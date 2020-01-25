//
//  PokemonDetailViewModel.swift
//  RotomPokedex
//
//  Created by Ryo on 2020/01/04.
//  Copyright © 2020 Ryoga. All rights reserved.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift

public class PokemonDetailViewModel {

    public struct Input {

        /// ビューが表示され終わった
        let viewDidAppear: Observable<Void>
        /// 表示アニメーションが終わった
        let animationCompleted: Observable<Void>
        /// ポケモンの画像の読み込み表示が終了した
        let showingLoadingViewFinished: Observable<Void>
        /// ポケモンの画像がタップされた
        let pokemonImageTapped: Observable<Void>
        /// ポケモンのデータが送られてきた
        let pokemonDataSent: Observable<Pokemon>
        /// 戻るボタンが押された
        let onBackButtonTapped: Observable<Void>
    }

    public struct Output {

        /// ビューを表示する
        let showViews: Driver<Void>
        /// ポケモンの画像の読み込みが開始した
        let loadingPokemonImageStarted: Driver<Void>
        /// ポケモンの画像
        let pokemonImage: Driver<UIImage>
        /// ポケモンの画像の読み込みに失敗した
        let pokemonImageErrorOccurred: Driver<Void>
        /// ポケモンのスプライト
        let pokemonSprite: Driver<UIImage>
        /// ポケモンのスプライト画像の読み込みに失敗した
        let pokemonSpriteErrorOccurred: Driver<Void>
        /// 前の画面に戻る
        let backToPreviousViewController: Driver<Void>
    }

    let useCase: PokemonDetailUseCaseProtocol
    let disposeBag = DisposeBag()

    public init<U : PokemonDetailUseCaseProtocol>(useCase: U) {
        self.useCase = useCase
    }

    public func transform(input: Input) -> Output {
        // 最初の表示完了イベント
        let firstViewDidAppear = input.viewDidAppear.take(1)

        // 表示アニメーションが終わった
        let animationCompleted = input.animationCompleted.take(1)
            .share()
        // 戻るボタンが押された
        let backButtonTapped = input.onBackButtonTapped
        // アニメーション完了後に戻るボタンが押されたとき
        let backButtonTappedAfterAnimationCompleted = animationCompleted
            .flatMapLatest { backButtonTapped }

        // 表示するポケモンの画像の番号
        let pokemonImageSuffixNumberBehaviorRelay = BehaviorRelay<Int>(value: 0)
        // 表示するポケモンの画像
        let pokemonImagesBehaviorRelay = BehaviorRelay<[UIImage]>(value: [])

        // ポケモンのデータが送られてきた
        let pokemonDataSent = input.pokemonDataSent
            .do(onNext: { _ in
                // 序数はリセットする
                // 1はprimaryImageと同じなので1始まり
                pokemonImageSuffixNumberBehaviorRelay.accept(0)
            })
        // 送られてきたポケモンの図鑑番号
        let pokedexNumber: Observable<Int> = pokemonDataSent
            .map { $0.number }
            .share()
        // ポケモンの画像の読み込みが開始した
        let loadingPokemonImageStarted = pokedexNumber
            .mapToVoid()

        // ポケモン画像の読み込み表示が終了した
        let showingLoadingViewFinished = input.showingLoadingViewFinished
        // ポケモン画像の読み込み表示終了を待つ図鑑番号
        // キャッシュがある場合は画像送出イベントが読み込み表示完了より早く走ることがあるので同期してやる
        let pokedexNumberAfterShowingLoadingViewFinished = Observable.zip(pokedexNumber, showingLoadingViewFinished) { (pokedexNumber, _) in
            pokedexNumber
        }

        // 表示するポケモンの画像の配列
        let tryToGetPokemonImages = pokedexNumberAfterShowingLoadingViewFinished
            .flatMapLatest { [unowned self] pokedexNumber in
                return self.useCase.findPokemonImages(byPokedexNumber: pokedexNumber)
                    .materialize()
            }
            .share()

        // ポケモンの画像が取得できた
        let pokemonImages = tryToGetPokemonImages
            .elements()
            .share()
        // 空でないポケモンの画像
        let nonEmptyPokemonImages = pokemonImages
            .filter { !$0.isEmpty }
            .share()
        // ポケモンの画像が空だった
        let emptyPokemonImages = pokemonImages
            .filter { $0.isEmpty }
            .mapToVoid()
        // リレーとバインド
        nonEmptyPokemonImages
            .bind(to: pokemonImagesBehaviorRelay)
            .disposed(by: disposeBag)

        // ポケモンの画像取得成功を通知する
        let gettingNonEmptyPokemonImagesSucceeded = nonEmptyPokemonImages
            .mapToVoid()
            .share()

        // ポケモンの画像取得でエラーが発生した
        let pokemonImagesErrorOccurred = tryToGetPokemonImages
            .errors()
            .mapToVoid()
        // 画像取得エラー
        let errorOccurred = Observable.merge(emptyPokemonImages, pokemonImagesErrorOccurred)

        // ポケモンのスプライト画像取得を試みる
        let tryToGetPokemonSprite = pokedexNumberAfterShowingLoadingViewFinished
            .flatMapLatest { [unowned self] pokedexNumber in
                return self.useCase.findPokemonSprite(byPokedexNumber: pokedexNumber)
                    .materialize()
            }
            .share()
        // ポケモンのスプライト画像を取得できた
        let pokemonSprite = tryToGetPokemonSprite
            .elements()
            .share()
        // ポケモンのスプライト画像がnilだった
        let nilPokemonSprite = pokemonSprite
            .filter { $0 == nil }
            .mapToVoid()
        // nilじゃないポケモンのスプライト画像
        let nonNilPokemonSprite = pokemonSprite
            .unwrap()

        // ポケモンのスプライト画像が取得できなかった
        let pokemonSpriteErrorOccurred = tryToGetPokemonSprite
            .errors()
            .mapToVoid()
        // ポケモンのスプライト画像エラー
        let pokemonSpriteErrors = Observable.merge(nilPokemonSprite, pokemonSpriteErrorOccurred)

        // ポケモンの画像がタップされた
        let pokemonImageTapeed = input.pokemonImageTapped
        // ポケモンの画像取得成功後にタップされた
        let pokemonImageTappedAfterGettingPokemonImagesSucceeded = gettingNonEmptyPokemonImagesSucceeded
            .flatMapLatest { _ in pokemonImageTapeed }
            // 画像が一種類しか取れていないならイベント中止
            .filter { _ in pokemonImagesBehaviorRelay.value.count > 1 }

        // 画像を切り替えるトリガー
        // 空でないポケモンの画像を取得できた、もしくは空でない画像取得成功後にポケモンの画像がタップされたらイベントが走る
        let changeImage = Observable.merge(
            gettingNonEmptyPokemonImagesSucceeded,
            pokemonImageTappedAfterGettingPokemonImagesSucceeded
        )

        // 表示するポケモンの画像
        let pokemonImage: Observable<UIImage> = changeImage
            .map { _ in
                let index = pokemonImageSuffixNumberBehaviorRelay.value
                let images = pokemonImagesBehaviorRelay.value
                // 番号が配列の長さを越していたらリセット
                if index >= images.count {
                    let newIndex = 0
                    pokemonImageSuffixNumberBehaviorRelay.accept(newIndex + 1)
                    return images[newIndex]
                } else {
                    pokemonImageSuffixNumberBehaviorRelay.accept(index + 1)
                    return images[index]
                }
            }

        return Output(
            showViews: firstViewDidAppear.asDriver(onErrorDriveWith: Driver.never()),
            loadingPokemonImageStarted: loadingPokemonImageStarted.asDriver(onErrorDriveWith: Driver.never()),
            pokemonImage: pokemonImage.asDriver(onErrorDriveWith: Driver.never()),
            pokemonImageErrorOccurred: errorOccurred.asDriver(onErrorDriveWith: Driver.never()),
            pokemonSprite: nonNilPokemonSprite.asDriver(onErrorDriveWith: Driver.never()),
            pokemonSpriteErrorOccurred: pokemonSpriteErrors.asDriver(onErrorDriveWith: Driver.never()),
            backToPreviousViewController: backButtonTappedAfterAnimationCompleted.asDriver(onErrorDriveWith: Driver.never())
        )
    }
}
