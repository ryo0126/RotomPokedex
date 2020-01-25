//
//  PokemonTableUseCase.swift
//  RotomPokedex
//
//  Created by Ryo on 2019/12/30.
//  Copyright © 2019 Ryoga. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

public protocol PokemonTableUseCaseProtocol {

    /// ポケモン図鑑に登録できる全てのポケモンのデータを取得する
    /// - Returns: 全てのポケモンのデータ
    func findAllPokemonData() -> Observable<[Pokemon]>

    /// ポケモン図鑑に登録できる全てのポケモンのデータを順番を指定して取得する
    /// - Returns: 全てのポケモンのデータ
    func findAllPokemonData(sortedBy: PokemonOrder) -> Observable<[Pokemon]>

    /// ポケモンの画像を取得する
    /// - Returns: 図鑑番号に対応したポケモンの画像
    func findPokemonImage(byPokedexNumber pokedex: Int) -> Observable<UIImage?>
}

public class PokemonTableUseCase : PokemonTableUseCaseProtocol {

    private let repository: PokemonRepositoryProtocol

    public init<R : PokemonRepositoryProtocol>(repository: R) {
        self.repository = repository
    }

    public func findAllPokemonData() -> Observable<[Pokemon]> {
        return repository.findAllPokemonData()
    }

    public func findAllPokemonData(sortedBy sorting: PokemonOrder) -> Observable<[Pokemon]> {
        return self.findAllPokemonData()
            .map { $0.sorted(by: sorting.rule) }
    }

    public func findPokemonImage(byPokedexNumber pokedex: Int) -> Observable<UIImage?> {
        return repository.findPrimaryPokemonGif(byPokedexNumber: pokedex)
    }
}

/// データソースに対するユースケース
public protocol PokemonTableDataSourceUseCaseProtocol {

    /// 指定された図鑑番号のポケモンのスプライトを取得する
    /// - Parameter byPokedexNumber: 図鑑番号
    /// - Returns: 指定された図鑑番号のポケモンのスプライト
    func findPokemonSprite(byPokedexNumber number: Int) -> Observable<UIImage>
}

public class PokemonTableDataSourceUseCase : PokemonTableDataSourceUseCaseProtocol {

    private let repository: PokemonRepositoryProtocol

    public init<R : PokemonRepositoryProtocol>(repository: R) {
        self.repository = repository
    }

    public func findPokemonSprite(byPokedexNumber number: Int) -> Observable<UIImage> {
        // 対応するポケモンが見つからなかった場合は無視
        return repository.findPokemonSprite(byPokedexNumber: number)
            .unwrap()
    }
}
