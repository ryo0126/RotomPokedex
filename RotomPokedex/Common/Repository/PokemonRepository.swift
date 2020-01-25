//
//  PokemonRepository.swift
//  RotomPokédex
//
//  Created by Ryo on 2019/12/29.
//  Copyright © 2019 Ryoga. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import SwiftyGif

// MARK: - Pokemon repository

// MARK: - Protocol

/// ポケモンのデータレポジトリ
public protocol PokemonRepositoryProtocol {

    /// ポケモン図鑑に登録できる全てのポケモンのデータのキャッシュを作成する
    /// - Returns: 完了を通知する`Observable`
    func fetchAllPokemonData() -> Observable<Void>

    /// ポケモン図鑑に登録できる全てのポケモンのデータを取得する
    /// - Returns: 全てのポケモンのデータ
    func findAllPokemonData() -> Observable<[Pokemon]>

    /// 指定された図鑑番号のポケモンのデータを取得する
    /// - Parameter byPokedexNumber: 図鑑番号
    /// - Returns: 指定された図鑑番号のポケモンのデータ。存在しない場合は`nil`
    func findPokemonData(byPokedexNumber number: Int) -> Observable<Pokemon?>

    /// 指定された図鑑番号のポケモンのGIF画像を取得する
    /// - Parameters:
    ///   - byPokedexNumber: 図鑑番号
    /// - Returns: 指定された図鑑番号のポケモンのGIF画像。存在しない場合は`nil`
    func findPrimaryPokemonGif(byPokedexNumber number: Int) -> Observable<UIImage?>

    /// 指定された図鑑番号のポケモンの他のGIF画像を取得する
    /// - Parameters:
    ///   - byPokedexNumber: 図鑑番号
    /// - Returns: 指定された図鑑番号のポケモンのGIF画像。存在しない場合は空の配列
    func findOtherPokemonGifs(byPokedexNumber number: Int) -> Observable<[UIImage]>

    /// 指定された図鑑番号のポケモンのスプライトを取得する
    /// - Parameter byPokedexNumber: 図鑑番号
    /// - Returns: 指定された図鑑番号のポケモンのスプライト。存在しない場合は`nil`
    func findPokemonSprite(byPokedexNumber number: Int) -> Observable<UIImage?>
}

// MARK: - Implementation -

/// ポケモンレポジトリのシングルトン具象クラス
public class PokemonRepository : PokemonRepositoryProtocol {

    // MARK: - Properties

    // MARK: Public properties

    /// グローバルインスタンス
    public static let shared: PokemonRepository = PokemonRepository()

    // MARK: Private properties

    /// ポケモンデータのキャッシュ
    private var dataCaches: [Pokemon]?
    /// ポケモンの英名のキャッシュ
    private var englishPokemonNameOfPokedexNumber: [Int:String]?

    // MARK: - Initializers

    private init() {}



    // MARK: - Methods

    // MARK: Public methods

    public func fetchAllPokemonData() -> Observable<Void> {
        return Observable<Void>.create { [unowned self] observer in
            // ダミーで取得処理を走らせてキャッシュを作成する
            let _ = self.getAllPokemonData()
            // 全てのポケモンの英名をキャッシュしておく
            self.fetchAllEnglishPokemonNames()
            observer.onCompleted()
            return Disposables.create()
        }
    }

    public func findAllPokemonData() -> Observable<[Pokemon]> {
        return Observable<[Pokemon]>.create { [unowned self] observer in
            // 購読されたらレポジトリからの取得処理を開始して通知
            let allPokemonData = self.getAllPokemonData()
            observer.onNext(allPokemonData)
            return Disposables.create()
        }
    }

    public func findPokemonData(byPokedexNumber number: Int) -> Observable<Pokemon?> {
        return Observable<Pokemon?>.create { [unowned self] observer in
            // 購読されたらレポジトリからの取得処理を開始して通知
            let pokemonData = self.getPokemonData(byPokedexNumber: number)
            observer.onNext(pokemonData)
            return Disposables.create()
        }
    }

    public func findPrimaryPokemonGif(byPokedexNumber number: Int) -> Observable<UIImage?> {
        // 英名が取得できない場合は空のObservableを返す
        guard let englishPokemonNameOfPokedexNumber = self.englishPokemonNameOfPokedexNumber,
            let englishPokemonName = englishPokemonNameOfPokedexNumber[number] else {
            return Observable.empty()
        }
        let targetName = "\(englishPokemonName.lowercased())"
        // キャッシュが存在するならばそれを返す
        if let cacheData = PrimaryPokemonGifCaches.shared.findCache(ofDataNamed: targetName) {
            return Observable.create { observer in
                let image = try? UIImage(gifData: cacheData)
                observer.onNext(image)
                return Disposables.create()
            }
        }

        // URLからダウンロードするObservableを返す
        let urlString = PokemonGifUrl.primary(pokemonName: targetName).urlString
        // 取得したデータをUIImageに直す
        return ObservableRequest.create(url: urlString)
            .do(onNext: { data in
                // データが取れていた場合はキャッシュする
                if let data = data {
                    PrimaryPokemonGifCaches.shared.save(data: data, asName: targetName)
                }
            })
            .map { data in
                // データが取れなかった場合はnilを流す
                guard let data = data else { return nil }
                return try? UIImage(gifData: data)
            }
    }

    public func findOtherPokemonGifs(byPokedexNumber number: Int) -> Observable<[UIImage]> {
        // 英名が取得できない場合は空のObservableを返す
        guard let englishPokemonNameOfPokedexNumber = self.englishPokemonNameOfPokedexNumber,
            let englishPokemonName = englishPokemonNameOfPokedexNumber[number] else {
            return Observable.empty()
        }
        let targetName = "\(englishPokemonName.lowercased())"
        // キャッシュが存在するならばそれを返す
        if let cacheData = OtherPokemonGifCaches.shared.findCache(ofDataNamed: targetName) {
            return Observable.create { observer in
                let image = cacheData
                    // 変換できなかったものは除外
                    .compactMap { try? UIImage(gifData: $0) }
                observer.onNext(image)
                return Disposables.create()
            }
        }

        // 画像取得リクエスト
        // xxx-2.gifからxxx-6.gifまでの取得を試みて、取得できた分だけ抽出
        let observableRequests = [Int](2...6)
            .map { index -> Observable<Data?> in
                // URLからダウンロードするObservableを作る
                let urlString = PokemonGifUrl.other(pokemonName: targetName, suffixNumber: index).urlString
                // 取得したデータをUIImageに直す
                return ObservableRequest.create(url: urlString)
                    // エラーをハンドリング
                    .catchError { error in
                        switch error {
                        // 404の場合はnilのObservableに変換する
                        case ErrorStatusCode.notFound:
                            return Observable.just(nil)
                        // それ以外はそのまま送出
                        default:
                            throw error
                        }
                    }
            }

        return Observable.zip(observableRequests)
            // 配列内からnilをふるい落とす
            .map { results in
                // nilを除いたData配列
                let nonNilResults = results
                    .compactMap { $0 }
                // キャッシュ
                OtherPokemonGifCaches.shared.save(data: nonNilResults, asName: targetName)
                return nonNilResults
                    .compactMap { try? UIImage(gifData: $0) }
            }
    }

    public func findPokemonSprite(byPokedexNumber number: Int) -> Observable<UIImage?> {
        let numberString = String(number)
        // キャッシュが存在するならばそれを返す
        if let cacheData = PokemonSpriteCaches.shared.findCache(ofDataNamed: numberString) {
            return Observable.create { observer in
                let image = UIImage(data: cacheData)
                observer.onNext(image)
                return Disposables.create()
            }
        }

        // URLからダウンロードするObservableを返す
        let urlString = PokemonImageUrl.sprite(pokedexNumber: number).urlString
        // 取得したデータをUIImageに直す
        return ObservableRequest.create(url: urlString)
            .do(onNext: { data in
                // データが取れていた場合はキャッシュする
                if let data = data {
                    PokemonSpriteCaches.shared.save(data: data, asName: numberString)
                }
            })
            .map { data in
                // データが取れなかった場合はnilを流す
                guard let data = data else { return nil }
                return UIImage(data: data)
            }
    }



    // MARK: - Private methods

    /// ポケモンデータの取得処理
    private func getPokemonData(byPokedexNumber number: Int) -> Pokemon? {
        // キャッシュがなければ作成
        if dataCaches == nil {
            let _ = findAllPokemonData()
        }
        let dataCaches = self.dataCaches!
        return dataCaches[number]
    }

    /// 全てのポケモンの英名をキャッシュする
    private func fetchAllEnglishPokemonNames() {
        // キャッシュが存在するなら何もしない
        if englishPokemonNameOfPokedexNumber != nil {
            return
        }
        guard let path = Bundle.main.path(forResource: "pokedex", ofType: "json") else {
            fatalError("Could not find \"pokedex.json\" file")
        }
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        let rawPokemonData = try! JSONDecoder().decode([LocalizedPokemonJson].self, from: data)
        let englishPokemonNames = rawPokemonData
            .reduce(into: [Int:String]()) { (map, pokemon) in
                // ニドラン♀/♂は表示が異なるので特殊対応
                if pokemon.id == 29 {
                    map[29] = "Nidoranf"
                } else if pokemon.id == 32 {
                    map[32] = "Nidoranm"
                } else {
                    map[pokemon.id] = pokemon.name.english
                }
            }
        self.englishPokemonNameOfPokedexNumber = englishPokemonNames
    }

    /// 全てのポケモンデータの取得処理
    private func getAllPokemonData() -> [Pokemon] {
        // キャッシュが存在するならそれを返す
        if let dataCaches = dataCaches {
            return dataCaches
        }
        guard let path = Bundle.main.path(forResource: "pokemon_data", ofType: "json") else {
            fatalError("Could not find \"pokemon_data.json\" file")
        }
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        let allRawPokemonData = try! JSONDecoder().decode([PokemonJson].self, from: data)
        let allPokemonData: [Pokemon] = allRawPokemonData
            .map { pokemon in
                let types: Pokemon.Types = (first: pokemon.types[0].asType,
                                            second: pokemon.types.count == 2 ? pokemon.types[1].asType : nil)
                return Pokemon(number: pokemon.no,
                               name: pokemon.name,
                               types: types,
                               abilities: pokemon.abilities,
                               hiddenAbilities: pokemon.hiddenAbilities,
                               baseStats: pokemon.stats)
            }
        // 図鑑番号が重複した要素を取り除く
        dataCaches = allPokemonData.reduce([Pokemon]()) { $0.contains($1) ? $0 : $0 + [$1] }
        return dataCaches!
    }
}



// MARK: - Codables -

fileprivate struct PokemonJson : Codable {

    let no: Int
    let name: String
    let types: [TypeJson]
    let abilities: [String]
    let hiddenAbilities: [String]
    let stats: BaseStats
}

fileprivate struct LocalizedPokemonJson : Codable {

    let id: Int
    let name: LocalizedPokemonNamesJson
}

fileprivate struct LocalizedPokemonNamesJson : Codable {

    let english: String
}

fileprivate enum TypeJson : String, Codable {

    case ノーマル
    case ほのお
    case みず
    case でんき
    case くさ
    case こおり
    case かくとう
    case どく
    case じめん
    case ひこう
    case エスパー
    case むし
    case いわ
    case ゴースト
    case ドラゴン
    case あく
    case はがね
    case フェアリー

    var asType: PokemonType {
        switch self {
        case .ノーマル:
            return .normal
        case .ほのお:
            return .fire
        case .みず:
            return .water
        case .でんき:
            return .electric
        case .くさ:
            return .grass
        case .こおり:
            return .ice
        case .かくとう:
            return .fighting
        case .どく:
            return .poison
        case .じめん:
            return .ground
        case .ひこう:
            return .flying
        case .エスパー:
            return .psychic
        case .むし:
            return .bug
        case .いわ:
            return .rock
        case .ゴースト:
            return .ghost
        case .ドラゴン:
            return .dragon
        case .あく:
            return .dark
        case .はがね:
            return .steel
        case .フェアリー:
            return .fairy
        }
    }
}
