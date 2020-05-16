//
//  PokemonDetailViewController.swift
//  RotomPokedex
//
//  Created by Ryo on 2020/01/04.
//  Copyright © 2020 Ryoga. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class PokemonDetailViewController: BaseViewController {

    struct Input {

        /// ポケモンリスト画面に戻る
        let backToTable: PublishRelay<Void>
        /// 前へ
        let showPrevious: PublishRelay<Void>
        /// 次へ
        let showNext: PublishRelay<Void>
    }

    struct Output {

        /// 次のポケモン詳細
        let nextPokemonDetail: Observable<Pokemon>
    }

    @IBOutlet var rootView: UIView!
    @IBOutlet weak var spriteImageView: UIImageView!
    @IBOutlet weak var pokemonImageView: UIImageView!
    @IBOutlet weak var unknownPokemonImageView: UILabel!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var numberLabelBackgroundView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nameLabelBackgroundView: UIView!
    @IBOutlet weak var typeValueLabel: UILabel!
    @IBOutlet weak var attributeValueLabel: UILabel!
    @IBOutlet weak var secondaryAttributeValueLabel: UILabel!
    @IBOutlet weak var hiddenAttributeValueLabel: UILabel!
    @IBOutlet weak var hpValueLabel: UILabel!
    @IBOutlet weak var attackValueLabel: UILabel!
    @IBOutlet weak var defenceValueLabel: UILabel!
    @IBOutlet weak var spAttackValueLabel: UILabel!
    @IBOutlet weak var spDefenceValueLabel: UILabel!
    @IBOutlet weak var speedValueLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var backButtonBackgroundView: UIView!

    @IBOutlet var leftEdgeToRightRecognizer: UIScreenEdgePanGestureRecognizer!
    @IBOutlet var upSwipeRecognizer: UISwipeGestureRecognizer!
    @IBOutlet var downSwipeRecognizer: UISwipeGestureRecognizer!

    /// 最初のポケモンデータ
    private let initialPokemon: Pokemon
    private let disposeBag = DisposeBag()

    /// ビューが表示された
    private let viewDidAppear = PublishRelay<Void>()
    /// 表示アニメーションが終わった
    private let animationCompleted = PublishRelay<Void>()
    /// ポケモン画像の読み込み表示が終了した
    private let showingLoadingViewFinished = PublishRelay<Void>()
    /// ポケモンの画像がタップされた
    private let onPokemonImageTapped = PublishRelay<Void>()
    /// 送られてきたポケモン
    private let sentPokemon = PublishRelay<Pokemon>()
    /// ポケモンリスト画面に戻る要求
    private let backToTable = PublishRelay<Void>()

    /// 前へ
    private let showPrevious = PublishRelay<Void>()
    /// 次へ
    private let showNext = PublishRelay<Void>()



    private let viewModel: PokemonDetailViewModel = {
        let repository = PokemonRepository.shared
        let useCase = PokemonDetailUseCase(repository: repository)
        return PokemonDetailViewModel(useCase: useCase)
    }()

    public init?(coder: NSCoder, initialPokemon: Pokemon) {
        self.initialPokemon = initialPokemon
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    /// このViewへの入力をバインドする
    /// - Parameters:
    ///   - input: 入力
    public func bindTo(input: Input) {
        // 戻るボタンのバインド
        backToTable.asObservable()
            .bind(to: input.backToTable)
            .disposed(by: disposeBag)
        // 前を表示のバインド
        showPrevious.asObservable()
            .bind(to: input.showPrevious)
            .disposed(by: disposeBag)
        // 前を表示のバインド
        showNext.asObservable()
            .bind(to: input.showNext)
            .disposed(by: disposeBag)
    }

    /// このViewへの出力をバインドする
    /// - Parameters:
    ///   - output: 出力
    public func bindTo(output: Output) {
        // 次のポケモンのバインド
        output.nextPokemonDetail
            .bind(to: sentPokemon)
            .disposed(by: disposeBag)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }

    private func setupUI() {
        // ポケモンリストの背景をそのまま使いたいのでこのルートビューの背景は透明にする
        rootView.backgroundColor = .clear
        // アニメーションで登場させるので最初は全て透明で操作不能にしておく
        rootView.alpha = 0
        rootView.isUserInteractionEnabled = false

        // 未指定で拡大するとドット絵がぼやけてしまうので.nearestを指定
        spriteImageView.layer.magnificationFilter = .nearest
        spriteImageView.layer.minificationFilter = .nearest
        pokemonImageView.layer.magnificationFilter = .nearest
        pokemonImageView.layer.minificationFilter = .nearest

        // ポケモン画像のタップイベントを監視
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onPokemonImageTapped(_:)))
        pokemonImageView.addGestureRecognizer(tapRecognizer)

        // 図鑑番号と名前欄の背景設定
        numberLabelBackgroundView.backgroundColor = .selectedCellOrange
        let nameLabelBackground = Trapezium()
        nameLabelBackground.fillColor = .black
        nameLabelBackgroundView.addSubview(nameLabelBackground)
        nameLabelBackground.fitToSuperview()

        // ボタンの画像が比率を保ちながら拡大されるようにするための設定
        backButton.imageView?.contentMode = .scaleAspectFit
        backButton.contentHorizontalAlignment = .fill
        backButton.contentVerticalAlignment = .fill
        // 戻るボタンの背景を丸くする
        backButtonBackgroundView.layer.masksToBounds = true
        let backButtonBackgroundWidth = backButtonBackgroundView.bounds.width
        backButtonBackgroundView.layer.cornerRadius = backButtonBackgroundWidth / 2
    }

    private func setupBindings() {
        let input = PokemonDetailViewModel.Input(
            viewDidAppear: viewDidAppear.asObservable(),
            animationCompleted: animationCompleted.asObservable(),
            showingLoadingViewFinished: showingLoadingViewFinished.asObservable(),
            pokemonImageTapped: onPokemonImageTapped.asObservable(),
            pokemonDataSent: sentPokemon.asObservable(),
            onBackButtonTapped: backButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input: input)

        // 表示アニメーションの再生
        output.showViews
            .drive(onNext: { [unowned self] _ in
                // 最初のポケモンデータを送る
                self.sentPokemon.accept(self.initialPokemon)
                // 表示用のアニメーションを再生する
                self.shiftViews(appear: true, completion: { [unowned self] in
                    // アニメーションの再生完了を通知
                    self.animationCompleted.accept(())
                    // 操作不能にしていたのを戻す
                    self.rootView.isUserInteractionEnabled = true
                })
            })
            .disposed(by: disposeBag)

        // 表示するポケモンのデータが送られてきた
        sentPokemon.asDriver(onErrorDriveWith: Driver.never())
            .drive(onNext: { [unowned self] pokemon in
                self.setupPokemonLabels(pokemon)
            })
            .disposed(by: disposeBag)

        // ポケモン画像の読み込みが開始したら画像をクリアする
        output.loadingPokemonImageStarted
            .drive(onNext: { [unowned self] _ in
                self.pokemonImageView.clearGifImage()
                // タップイベントが起こらないようにする
                self.pokemonImageView.isUserInteractionEnabled = false
                self.spriteImageView.image = UIImage()
                self.unknownPokemonImageView.isHidden = true
                // 読み込みの表示が完了したことを通知
                self.showingLoadingViewFinished.accept(())
            })
            .disposed(by: disposeBag)

        // ポケモンの画像
        output.pokemonImage
            .drive(onNext: { [unowned self] pokemonImage in
                self.unknownPokemonImageView.isHidden = true
                // 一度画像をリフレッシュ
                self.pokemonImageView.clearGifImage()
                self.pokemonImageView.setImage(pokemonImage, loopCount: -1)
                self.pokemonImageView.setGifScale(2.2)
                // タップイベントを有効にする
                self.pokemonImageView.isUserInteractionEnabled = true
            })
            .disposed(by: disposeBag)
        // ポケモンの画像が取得できなかった
        output.pokemonImageErrorOccurred
            .drive(onNext: { [unowned self] _ in
                self.pokemonImageView.clearGifImage()
                self.unknownPokemonImageView.isHidden = false
            })
            .disposed(by: disposeBag)

        // ポケモンのスプライト
        output.pokemonSprite
            .drive(onNext: { [unowned self] image in
                self.spriteImageView.image = image
            })
            .disposed(by: disposeBag)
        // ポケモンのスプライトが取得できなかった
        output.pokemonSpriteErrorOccurred
            .drive(onNext: { [unowned self] in
                self.spriteImageView.image = UIImage()
            })
            .disposed(by: disposeBag)

        // 前の画面に戻る
        output.backToPreviousViewController
            .drive(onNext: { [unowned self] _ in
                // 安全にアニメーションするため操作不能にする
                self.view.isUserInteractionEnabled = false
                // 隠れるアニメーションを再生
                self.shiftViews(appear: false, completion: { [unowned self] in
                    // 自分自身を破棄
                    self.dismiss(animated: false, completion: { [unowned self] in
                        // 完了したら戻る要求を依存先に送る
                        self.backToTable.accept(())
                    })
                })
            })
            .disposed(by: disposeBag)
    }

    /// 表示内容を更新する
    /// - Parameter pokemon: 表示対象のポケモン
    private func setupPokemonLabels(_ pokemon: Pokemon) {
        numberLabel.text = String(format: "No.%03d", pokemon.number)
        nameLabel.text = pokemon.name

        let firstType = pokemon.types.first
        if let secondType = pokemon.types.second {
            typeValueLabel.text = "\(firstType.rawValue) \(secondType.rawValue)"
        } else {
            typeValueLabel.text = firstType.rawValue
        }

        attributeValueLabel.text = pokemon.abilities[0]
        if pokemon.abilities.count == 2 {
            secondaryAttributeValueLabel.text = pokemon.abilities[1]
        } else {
            secondaryAttributeValueLabel.text = "-"
        }

        if pokemon.hiddenAbilities.isEmpty {
            hiddenAttributeValueLabel.text = "-"
        } else {
            hiddenAttributeValueLabel.text = pokemon.hiddenAbilities.joined(separator: ", ")
        }

        hpValueLabel.text = String(pokemon.baseStats.hp)
        attackValueLabel.text = String(pokemon.baseStats.attack)
        defenceValueLabel.text = String(pokemon.baseStats.defence)
        spAttackValueLabel.text = String(pokemon.baseStats.spAttack)
        spDefenceValueLabel.text = String(pokemon.baseStats.spDefence)
        speedValueLabel.text = String(pokemon.baseStats.speed)
    }

    /// ビューをずらすアニメーションを再生する
    /// - Parameters:
    ///   - appear: 登場時かどうか
    ///   - completion: コンプリーションハンドラ
    private func shiftViews(appear: Bool, completion: (() -> Void)? = nil) {
        let screenWidth = UIScreen.main.bounds.width
        let distance = screenWidth / 25
        // 出現の場合は左から右へ入ってくるように見せたいので初期位置をずらしておく
        if appear {
            rootView.bounds.origin.x -= distance
        }
        UIView.animate(withDuration: 0.1, animations: { [unowned self] in
            let alpha: CGFloat = appear ? 1 : 0
            self.rootView.alpha = alpha

            self.rootView.bounds.origin.x += distance * (appear ? 1 : -1)
        }, completion: { _ in completion?() })
    }

    /// ビューが表示された
    override func viewDidAppear(_ animated: Bool) {
        viewDidAppear.accept(())
        super.viewDidAppear(animated)
    }

    /// ポケモン画像がタップされた
    @objc private func onPokemonImageTapped(_ sender: UIImageView) {
        onPokemonImageTapped.accept(())
    }

    /// 画面左端でスワイプされたとき
    @IBAction func onBackSwiped(_ sender: UIScreenEdgePanGestureRecognizer) {
        // デフォルトだと指が動くたびに通知されるのでパン終了だけ対象にする
        if sender.state == .recognized {
            // 戻るボタンを押したことにする
            backButton.sendActions(for: .touchUpInside)
        }
    }

    /// 上にスワイプされたとき
    @IBAction func onUpSwiped(_ sender: UISwipeGestureRecognizer) {
        showNext.accept(())
    }

    /// 下にスワイプされたとき
    @IBAction func onDownSwiped(_ sender: UISwipeGestureRecognizer) {
        showPrevious.accept(())
    }
}
