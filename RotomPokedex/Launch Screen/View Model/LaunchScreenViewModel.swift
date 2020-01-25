//
//  LaunchScreenViewModel.swift
//  RotomPokédex
//
//  Created by Ryo on 2019/12/29.
//  Copyright © 2019 Ryoga. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

public class LaunchScreenViewModel {

    public struct Input {

        /// Viewの読み込みが完了した
        let viewDidLoad: Observable<Void>
    }

    public struct Output {

        /// 次に表示する`ViewController`
        let nextViewController: Driver<UIViewController>
    }

    private let useCase: LaunchScreenUseCaseProtocol
    private let disposeBag: DisposeBag = DisposeBag()

    public init<U : LaunchScreenUseCaseProtocol>(useCase: U) {
        self.useCase = useCase
    }

    public func transform(input: Input) -> Output {
        // データロードが完了した
        let dataDidLoad = PublishRelay<Void>()
        // 次に表示するViewController
        let nextViewControllerAfterDataLoaded: Observable<UIViewController> = dataDidLoad
            .map { _ in
                return UIStoryboard(name: "Main", bundle: nil)
                    .instantiateInitialViewController()
            }
            .unwrap()

        // Viewの読み込みが完了した
        // take(1)しないとflatMap先でcompletedが流れてくれないのでしておく
        let viewDidLoad = input.viewDidLoad.take(1)
        // ポケモンの全てのデータを読み込む
        let fetchingAllPokemonData: Observable<Void> = viewDidLoad
            .flatMapLatest { [unowned self] _ in
                return self.useCase.fetchAllPokemonData()
            }

        fetchingAllPokemonData
            .subscribe(onCompleted: {
                // 完了したらdataDidLoadに流す
                dataDidLoad.accept(())
            })
            .disposed(by: disposeBag)

        return Output(nextViewController: nextViewControllerAfterDataLoaded.asDriver(onErrorDriveWith: Driver.never()))
    }
}
