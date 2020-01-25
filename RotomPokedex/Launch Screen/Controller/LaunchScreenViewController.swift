//
//  LaunchScreenViewController.swift
//  RotomPokédex
//
//  Created by Ryo on 2019/12/29.
//  Copyright © 2019 Ryoga. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// 起動時に表示される
/// ロード処理などをやって完了したら最初の`ViewController`へ移動
class LaunchScreenViewController: UIViewController {

    @IBOutlet weak var pokedexImageView: UIImageView!
    weak var pvc: UIViewController?

    let viewModel: LaunchScreenViewModel = {
        let repository = PokemonRepository.shared
        let useCase = LaunchScreenUseCase(repository: repository)
        return LaunchScreenViewModel(useCase: useCase)
    }()

    let viewDidLoadTrigger = PublishRelay<Void>()
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }

    private func setupUI() {
        pvc = self.presentingViewController
    }

    private func setupBindings() {
        let input = LaunchScreenViewModel.Input(viewDidLoad: viewDidLoadTrigger.single())
        let output = viewModel.transform(input: input)
        output
            .nextViewController
            .drive(onNext: { [unowned self] next in
                self.dismiss(animated: false, completion: {
                    guard let delegate = UIApplication.shared.delegate as? AppDelegate,
                        let window = delegate.window else {
                        fatalError("Could not get UIWindow instance.")
                    }
                    window.rootViewController = next
                    UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
                })
            })
            .disposed(by: disposeBag)
    }

    /// ビューが表示されたとき
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 安全のためviewDidLoadではなくてこちらでイベント送出
        // viewDidAppearは表示されるたびに呼び出されるが、この画面は一度しか表示しないので複数回呼ばれる心配はしなくてOK
        viewDidLoadTrigger.accept(())
    }
}
