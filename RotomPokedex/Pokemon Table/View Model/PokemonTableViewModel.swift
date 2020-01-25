//
//  PokemonTableViewModel.swift
//  RotomPokedex
//
//  Created by Ryo on 2019/12/30.
//  Copyright © 2019 Ryoga. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import RxSwiftExt

/// ポケモンリストのビューモデル
public class PokemonTableViewModel {

    public struct Input {

        /// Viewの読み込みが完了した
        let viewDidLoad: Observable<Void>
        /// セルがタップされた
        let pokemonTableCellTapped: Observable<Int?>
        /// 読み込み画像の表示が終わった
        let showingLoadingViewFinished: Observable<Void>
        /// 前回タップされたセル
        let previousTappedCell: Observable<Int?>
        /// 並び替えボタンがタップされた
        let sortButtonTapped: Observable<PokemonOrder>
    }

    public struct Output {

        /// 全てのポケモンのデータ
        let allPokemonData: Observable<[Pokemon]>
        /// ポケモンの画像ロードが開始した
        let loadingPokemonImageStarted: Driver<Void>
        /// ポケモンの詳細画像
        let pokemonImage: Driver<UIImage>
        /// ポケモンの画像エラー
        let pokemonImageErrorOccurred: Driver<Void>
        /// ポケモンの詳細`ViewController`
        let pokemonDetailViewController: Driver<PokemonDetailViewController>
        /// 選択行を変更する
        let selectRow: Driver<Int>
        /// 並び替えが終了した
        let sortFinished: Driver<PokemonOrder>
        /// 戻られたときの準備
        let prepareForBack: Driver<Void>
    }

    /// 詳細画面との連携用
    /// ポケモンの詳細画面から戻るイベント
    private let backToTableRelay = PublishRelay<Void>()
    /// 前を選択
    private let showPreviousRelay = PublishRelay<Void>()
    /// 次を選択
    private let showNextRelay = PublishRelay<Void>()

    let useCase: PokemonTableUseCaseProtocol
    let dataSource: PokemonTableDataSource
    let disposeBag = DisposeBag()

    public init<U : PokemonTableUseCaseProtocol>(useCase: U, dataSource: PokemonTableDataSource) {
        self.useCase = useCase
        self.dataSource = dataSource
    }

    public func transform(input: Input) -> Output {
        // 前回選択された行
        let previousTappedCell = input.previousTappedCell
        // セルがタップされた
        // 他より先にイベントが流れないようにpublishして処理開始タイミングを制御
        let cellTapped = input.pokemonTableCellTapped
            .publish()

        // 選択されたセルのリレー
        let selectedCellBehaviorRelay = BehaviorRelay<Int?>(value: nil)

        // Viewの読み込みが完了した
        // 一度しか流れないのは自明なのでtake(1)
        let viewDidLoad = input.viewDidLoad.take(1)
            .share()
        viewDidLoad
            .subscribe(onNext: { [unowned self] _ in
                // ビューが読み込まれた後にconnectして処理開始
                cellTapped
                    .connect()
                    .disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
        // 選択されたセルのリレーとバインド
        cellTapped
            .bind(to: selectedCellBehaviorRelay)
            .disposed(by: disposeBag)

        // 全てのポケモンデータ
        let allPokemonData: Observable<[Pokemon]> = viewDidLoad
            .flatMapLatest { [unowned self] _ in
                return self.useCase.findAllPokemonData()
            }

        // 前回と現在選択されたセル
        let currentAndPreviousTappedCell = Observable.zip(cellTapped, previousTappedCell)
            .share()
        // 前回と同じセルがタップされた
        let sameCellTapped = currentAndPreviousTappedCell
            .filter { (current, previous) in
                return current == previous
            }
            .map { (current, previous) in
                return current
            }
            // nilは流さない
            .unwrap()
        // 前回と違うセルがタップされた
        let differentCellTapped = currentAndPreviousTappedCell
            .filter { (current, previous) in
                return current != previous
            }
            .map { (current, previous) in
                return current
            }
            // nilは流さない
            .unwrap()
            .share()

        // 違うセルがタップされたときは画像読み込み開始を流す
        let loadingPokemonImageStarted: Observable<Void> = differentCellTapped
            .map { _ in () }
            .share()
        // タップされたポケモン
        let tappedPokemon = differentCellTapped
            .map { [unowned self] row in
                return self.dataSource.allPokemonData[row]
            }
        // 二回タップされたポケモン
        let doubleTappedPokemon = sameCellTapped
            .map { [unowned self] row in
                return self.dataSource.allPokemonData[row]
            }

        // 読み込みの表示が終わった
        let showingLoadingViewFinished = input.showingLoadingViewFinished

        // 読み込み表示完了後に流れるタップされたポケモン
        // キャッシュがある場合は読み込み表示よりも先にイベントが流れることがあるのでzipで同期してあげる
        let tappedPokemonAfterShowingLoadingViewFinished = Observable.zip(tappedPokemon, showingLoadingViewFinished) { (pokemon, _) in
                return pokemon
            }

        // タップされたポケモンの図鑑番号
        let tappedPokedexNumber = tappedPokemonAfterShowingLoadingViewFinished
            .map { $0.number }
        // ポケモンの画像の取得を試みる
        let tryToFindPokemonImage = tappedPokedexNumber
            .flatMapLatest { [unowned self] pokedex in
                // materializeしてエラーで停止しないようにする
                // Note: エラーしうるObservableにflatMapした場合、flatMapブロック内でエラーするとそのブロック内でエラーが流されて即座にObservableが停止してしまう
                //   したがってエラーしうるObservableにflatMapしてmaterializeしたい場合は、flatMapブロック内でそのObservableをmaterializeする必要がある
                return self.useCase.findPokemonImage(byPokedexNumber: pokedex)
                    .materialize()
            }
            .share()

        // ポケモンの画像が取得できた
        let pokemonImage: Observable<UIImage?> = tryToFindPokemonImage
            .elements()
            .share()
        // ポケモンの画像がnilじゃなかった
        let nonNilPokemonImage = pokemonImage
            .unwrap()
        // ポケモンの画像がnilだった
        let nilPokemonImage = pokemonImage
            .filter { $0 == nil }
            .mapToVoid()
        // ポケモンの画像取得でエラーが起きた
        let pokemonImageErrorOccurred = tryToFindPokemonImage
            .errors()
            .mapToVoid()
        // 画像取得エラー
        let errorOccurred = Observable.merge(nilPokemonImage, pokemonImageErrorOccurred)

        // 戻るための準備
        let prepareForBack = self.backToTableRelay.asObservable()
            .share()
        // ポケモンの詳細から戻ってきたときに選択する行のリレー
        let rowToSelectWhenBackToTableBehaviorRelay = BehaviorRelay<Int?>(value: nil)

        // 前へ
        let showPrevious = self.showPreviousRelay.asObservable()
        // 次へ
        let showNext = self.showNextRelay.asObservable()
        // 前のセル選択要求後に現在選択されているセルを流す
        let selectedCellAfterRequestingToShowPrevious = showPrevious
            .map { rowToSelectWhenBackToTableBehaviorRelay.value }
            // nilは流さない
            .unwrap()
            .share()
        // 次のセル選択要求後に現在選択されているセルを流す
        let selectedCellAfterRequestingToShowNext = showNext
            .map { rowToSelectWhenBackToTableBehaviorRelay.value }
            // nilは流さない
            .unwrap()
            .share()
        // 前の行番号
        let previousCell: Observable<Int> = selectedCellAfterRequestingToShowPrevious
            .map { [unowned self] row in
                let previousIndex = row - 1
                // 0未満になったら一番最後の行を選択する
                if previousIndex < 0 {
                    let maxIndex = self.dataSource.allPokemonData.count - 1
                    return maxIndex
                }
                return previousIndex
            }
        // 次の行番号
        let nextCell: Observable<Int> = selectedCellAfterRequestingToShowNext
            .map { [unowned self] row in
                let nextIndex = row + 1
                let maxIndex = self.dataSource.allPokemonData.count - 1
                // 最後の行を越したら0番目の行を選択する
                if nextIndex > maxIndex {
                    let minIndex = 0
                    return minIndex
                }
                return nextIndex
            }

        // 行の選択
        let selectRow = Observable.merge(previousCell, nextCell)
            .share()

        // 戻ったときに選択する行と行の選択イベントをバインド
        selectRow
            .bind(to: rowToSelectWhenBackToTableBehaviorRelay)
            .disposed(by: disposeBag)
        // 戻ったときに選択する行と選択されている行をバインド
        selectedCellBehaviorRelay
            .bind(to: rowToSelectWhenBackToTableBehaviorRelay)
            .disposed(by: disposeBag)

        // ポケモンの詳細から戻ってきたときに選択する行
        let rowToSelectWhenBackToTable = prepareForBack
            // すでに選択されている行だった場合は流さない
            .filter {
                selectedCellBehaviorRelay.value != rowToSelectWhenBackToTableBehaviorRelay.value
            }
            .map { rowToSelectWhenBackToTableBehaviorRelay.value }
            // nilは流さない
            .unwrap()

        // 行選択イベントに対応したポケモン
        let pokemonToSelect = selectRow
            .map { [unowned self] row in
                return self.dataSource.allPokemonData[row]
            }
        // 次のポケモン
        let nextPokemonDetail = Observable.merge(doubleTappedPokemon, pokemonToSelect)

        // ポケモンの詳細のViewController
        let pokemonDetailViewController: Observable<PokemonDetailViewController> = doubleTappedPokemon
            .map { pokemon in
                // ViewControllerを生成
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let detailViewController = storyboard.instantiateViewController(
                    identifier: String(describing: PokemonDetailViewController.self),
                    creator: { coder in
                        PokemonDetailViewController(coder: coder, initialPokemon: pokemon)
                    }
                )

                // ポケモンの詳細画面用のObservableを作ってイベントバインド
                let input = PokemonDetailViewController.Input(
                    backToTable: self.backToTableRelay,
                    showPrevious: self.showPreviousRelay,
                    showNext: self.showNextRelay
                )
                detailViewController.bindTo(input: input)
                let output = PokemonDetailViewController.Output(nextPokemonDetail: nextPokemonDetail)
                detailViewController.bindTo(output: output)

                return detailViewController
            }

        // 並び替えボタンが押された
        let sortButtonTapped = input.sortButtonTapped
            .share()
        // 並び替え
        let sortedAllPokemonData = sortButtonTapped
            .flatMapLatest { [unowned self] order in
                return self.useCase.findAllPokemonData(sortedBy: order)
            }
            .share()
        // 並び替えが終了した
        let sortFinished = Observable.zip(sortButtonTapped, sortedAllPokemonData) { (order, pokemon) in order }
        // 全てのポケモンのデータ
        let pokemonData = Observable.merge(allPokemonData, sortedAllPokemonData)

        return Output(
            allPokemonData: pokemonData,
            loadingPokemonImageStarted: loadingPokemonImageStarted.asDriver(onErrorDriveWith: Driver.never()),
            pokemonImage: nonNilPokemonImage.asDriver(onErrorDriveWith: Driver.never()),
            pokemonImageErrorOccurred: errorOccurred.asDriver(onErrorDriveWith: Driver.never()),
            pokemonDetailViewController: pokemonDetailViewController.asDriver(onErrorDriveWith: Driver.never()),
            selectRow: rowToSelectWhenBackToTable.asDriver(onErrorDriveWith: Driver.never()),
            sortFinished: sortFinished.asDriver(onErrorDriveWith: Driver.never()),
            prepareForBack: prepareForBack.asDriver(onErrorDriveWith: Driver.never())
        )
    }
}

/// ポケモンリストのデータソース
public class PokemonTableDataSource: NSObject, RxTableViewDataSourceType, UITableViewDataSource {

    public typealias Element = [Pokemon]

    /// データソース
    /// 全ポケモンのデータ
    var allPokemonData: [Pokemon] = []

    let useCase: PokemonTableDataSourceUseCaseProtocol

    public init<U : PokemonTableDataSourceUseCaseProtocol>(useCase: U) {
        self.useCase = useCase
    }

    /// オブザーブイベントが発生したとき
    public func tableView(_ tableView: UITableView, observedEvent: Event<[Pokemon]>) {
        if case .next(let allPokemonData) = observedEvent {
            self.allPokemonData = allPokemonData
            tableView.reloadData()
        }
    }

    /// セクション数
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    /// 行数
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allPokemonData.count
    }

    /// セル生成
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PokemonTableViewCell.self)) as! PokemonTableViewCell
        // 行番号
        let row = indexPath.row
        let pokemon = allPokemonData[row]
        let pokedexNumber = pokemon.number
        let name = pokemon.name
        // 画像は非同期で読み込むのでObservableを渡す
        let fetchPokemonSprite = useCase
            .findPokemonSprite(byPokedexNumber: pokedexNumber)
            // 以降の処理はUI変更処理なのでメインスレッドでやってもらう
            .observeOn(MainScheduler.instance)
        cell.setParameters(PokemonTableViewCell.Parameters(observableSprite: fetchPokemonSprite,
                                                           number: pokedexNumber,
                                                           name: name))
        return cell
    }
}
