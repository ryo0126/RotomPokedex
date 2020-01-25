//
//  PokemonTableViewController.swift
//  RotomPokédex
//
//  Created by Ryo on 2019/12/29.
//  Copyright © 2019 Ryoga. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyGif

class PokemonTableViewController: BaseViewController {

    @IBOutlet weak var movableSafeAreaLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewLeadingConstraint: NSLayoutConstraint!
    // 弱参照だとisActiveを切ったときにviewからも参照が切れてインスタンス解放されてしまうので強参照にする
    @IBOutlet var pokemonTableAndBackgoundLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var rotomPokedexTrailingConstraint: NSLayoutConstraint!
    var rootViewAndBackgroundLeadingConstraint: NSLayoutConstraint!

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var pokemonTable: UITableView!
    @IBOutlet weak var allTableBackgroundWrapperView: UIView!
    @IBOutlet weak var tableBackgroundWrapperView: UIView!
    @IBOutlet weak var secondaryTableBackgroundWrapperView: UIView!
    @IBOutlet weak var tertiaryTableBackgroundWrapperView: UIView!
    @IBOutlet weak var quaternaryTableBackgroundWrapperView: UIView!
    @IBOutlet weak var leftTopBar: UIView!
    @IBOutlet weak var topBar: UIView!
    @IBOutlet weak var topBarItemsWrapperView: UIView!
    @IBOutlet weak var scrollToTop: UIButton!
    @IBOutlet weak var orderLabel: UILabel!
    @IBOutlet weak var sortButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var pokemonImageView: UIImageView!
    @IBOutlet weak var unknownPokemonImageView: UILabel!
    weak var topBarMaskView: UIView!

    /// ビューモデル
    private var viewModel: PokemonTableViewModel = {
        let repository = PokemonRepository.shared
        let viewModelUseCase = PokemonTableUseCase(repository: repository)
        let dataSourceUseCase = PokemonTableDataSourceUseCase(repository: repository)
        let dataSource = PokemonTableDataSource(useCase: dataSourceUseCase)
        return PokemonTableViewModel(useCase: viewModelUseCase, dataSource: dataSource)
    }()

    /// ビューが読み込まれたのを通知する
    private let viewDidLoadTrigger = PublishRelay<Void>()
    /// 画像の読み込みの表示が終わった
    private let showingLoadingViewFinished = PublishRelay<Void>()
    /// セルが選択されたのを通知する
    private let pokemonTableCellTapped = BehaviorRelay<Int?>(value: nil)
    /// ひとつ前に選択されたセル
    private let previousTappedCell = BehaviorRelay<Int?>(value: nil)
    /// 並び替えボタンが押されたことを通知する
    private let sortButtonTapped = PublishRelay<PokemonOrder>()

    /// リスト背景の初期位置(アニメーション用)
    private var initialTableBackgroundX: CGFloat!
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }

    private func setupUI() {
        pokemonTable.delegate = self
        // セルのドロップシャドウが見えるようclipsToBoundsは切っておく
        pokemonTable.clipsToBounds = true
        // スクロールバーの自動調節をオフ
        // これをしないとNavigationBarにかぶる部分だけのインセットが自動追加されてしまう
        pokemonTable.automaticallyAdjustsScrollIndicatorInsets = false
        pokemonTable.backgroundColor = .clear

        // 未指定で拡大するとドット絵がぼやけてしまうので.nearestを指定
        pokemonImageView.layer.magnificationFilter = .nearest
        pokemonImageView.layer.minificationFilter = .nearest

        // リストの一番後ろの背景
        let tableBackground = Trapezium()
        tableBackground.fillColor = .backgroundOrange
        tableBackground.layer.shadowColor = UIColor.black.cgColor
        tableBackground.layer.shadowOffset = CGSize(width: 0, height: 1)
        tableBackground.layer.shadowRadius = 15
        tableBackground.layer.shadowOpacity = 0.3
        // リストの2つ目の背景
        let secondaryTableBackground = Trapezium()
        secondaryTableBackground.fillColor = .secondaryBackgroundOrange
        // リストの3つ目の背景
        let tertiaryTableBackground = Trapezium()
        tertiaryTableBackground.fillColor = .backgroundOrange
        // リストの4つ目の背景
        let quaternaryTableBackground = Trapezium()
        quaternaryTableBackground.fillColor = .white

        tableBackgroundWrapperView.addSubview(tableBackground)
        tableBackground.fitToSuperview()
        secondaryTableBackgroundWrapperView.addSubview(secondaryTableBackground)
        secondaryTableBackground.fitToSuperview()
        tertiaryTableBackgroundWrapperView.addSubview(tertiaryTableBackground)
        tertiaryTableBackground.fitToSuperview()
        quaternaryTableBackgroundWrapperView.addSubview(quaternaryTableBackground)
        quaternaryTableBackground.fitToSuperview()

        // 上の黒いバーのマスク用ビュー
        // ちょうど背景と同じように切り抜きたいので同じように作成する
        let topBarMaskView = Trapezium()
        self.topBarMaskView = topBarMaskView
        tableBackgroundWrapperView.addSubview(topBarMaskView)
        // ちょうどの大きさにすると少し左側が削れすぎるのでオフセットする
        topBarMaskView.fitToSuperview(
            withInsets: UIEdgeInsets(top: 0, left: -6.3, bottom: 0, right: 0)
        )

        // ソートボタンと検索ボタンの画像をアスペクト比を保ったままボタンの最大サイズに拡大する
        sortButton.imageView?.contentMode = .scaleAspectFit
        sortButton.contentHorizontalAlignment = .fill
        sortButton.contentVerticalAlignment = .fill
        searchButton.imageView?.contentMode = .scaleAspectFit
        searchButton.contentHorizontalAlignment = .fill
        searchButton.contentVerticalAlignment = .fill
    }

    private func setupBindings() {
        // セルを登録
        pokemonTable.register(
            UINib(nibName: String(describing: PokemonTableViewCell.self), bundle: nil),
            forCellReuseIdentifier: String(describing: PokemonTableViewCell.self)
        )

        let input = PokemonTableViewModel.Input(
            viewDidLoad: viewDidLoadTrigger.asObservable(),
            pokemonTableCellTapped: pokemonTableCellTapped.asObservable(),
            showingLoadingViewFinished: showingLoadingViewFinished.asObservable(),
            previousTappedCell: previousTappedCell.asObservable(),
            sortButtonTapped: sortButtonTapped.asObservable()
        )
        let output = viewModel.transform(input: input)

        // ポケモンの図鑑番号と名前のデータはテーブルにデータバインディング
        output.allPokemonData
            .bind(to: pokemonTable.rx.items(dataSource: viewModel.dataSource))
            .disposed(by: disposeBag)

        // 画像の読み込みが始まったら画像をクリアする
        output.loadingPokemonImageStarted
            .drive(onNext: { [unowned self] in
                self.pokemonImageView.clearGifImage()
                self.unknownPokemonImageView.isHidden = true
                // 読み込み開始処理が終了したことを通知
                self.showingLoadingViewFinished.accept(())
            })
            .disposed(by: disposeBag)

        // ポケモンの画像が流れてきたら左側に表示する
        output.pokemonImage
            .drive(onNext: { [unowned self] pokemonImage in
                self.unknownPokemonImageView.isHidden = true
                self.pokemonImageView.setImage(pokemonImage, loopCount: -1)
                self.pokemonImageView.setGifScale(1.8)
            })
            .disposed(by: disposeBag)

        // ポケモンの画像読み込みでエラーが発生したら画像をクリアしてはてなマークを表示する
        output.pokemonImageErrorOccurred
            .drive(onNext: { [unowned self] _ in
                self.pokemonImageView.clearGifImage()
                self.unknownPokemonImageView.isHidden = false
            })
            .disposed(by: disposeBag)

        // ポケモンの詳細ViewControllerが流れてきたらビューをスクロールしながら表示
        output.pokemonDetailViewController
            .drive(onNext: { [unowned self] viewController in
                // 安全にアニメーションできるよう操作不能にしておく
                self.view.isUserInteractionEnabled = false
                self.toggleTopBarAndTable(appear: false, completion: { [unowned self] in
                    self.shiftBackground(toRight: false, completion: {
                        viewController.modalPresentationStyle = .overFullScreen
                        self.present(viewController, animated: false)
                    })
                })
            })
            .disposed(by: disposeBag)

        // 詳細画面からの入力
        // ポケモンの詳細画面から戻る
        output.prepareForBack
            .drive(onNext: { [unowned self] _ in
                self.shiftBackground(toRight: true, completion: { [unowned self] in
                    self.toggleTopBarAndTable(appear: true, completion: { [unowned self] in
                        // 操作不能にしていたのを元に戻す
                        self.view.isUserInteractionEnabled = true
                    })
                })
            })
            .disposed(by: disposeBag)
        // 特定の行を選択
        output.selectRow
            .drive(onNext: { [unowned self] index in
                let indexPath = IndexPath(row: index, section: 0)
                guard let nextIndexPath = self.tableView(self.pokemonTable, willSelectRowAt: indexPath) else { return }
                self.pokemonTable.selectRow(at: nextIndexPath, animated: false, scrollPosition: .middle)
                self.tableView(self.pokemonTable, didSelectRowAt: nextIndexPath)
            })
            .disposed(by: disposeBag)

        // 並び替えが終了した
        output.sortFinished
            .drive(onNext: { [unowned self] order in
                // 順番のラベルを更新
                self.orderLabel.text = order.rawValue
                // 画像をクリアする
                self.unknownPokemonImageView.isHidden = true
                self.pokemonImageView.clearGifImage()
            })
            .disposed(by: disposeBag)
    }

    /// トップバーをずらすアニメーションを再生する
    /// - Parameters:
    ///   - appear: 登場時かどうか
    ///   - completion: コンプリーションハンドラ
    private func toggleTopBarAndTable(appear: Bool, completion: (() -> Void)? = nil) {
        let screenWidth = UIScreen.main.bounds.width
        let distance = screenWidth / 5 * (appear ? -1 : 1)
        // 動かしたいビューは全てcontentViewとmovableSafeAreaとの相対で制約がつけられているので
        // この二つを動かせば全部動く
        contentViewLeadingConstraint.constant += distance
        movableSafeAreaLeadingConstraint.constant += distance

        // 背景がつられて動かないように制約を切り替える
        pokemonTableAndBackgoundLeadingConstraint.isActive = appear
        rootViewAndBackgroundLeadingConstraint.isActive = !appear

        UIView.animate(withDuration: 0.125, animations: { [unowned self] in
            self.contentView.alpha = appear ? 1 : 0
            self.view.layoutIfNeeded()
        }, completion: {  _ in completion?() })
    }

    /// 背景をずらすアニメーションを再生する
    /// - Parameters:
    ///   - toRight: 登場時かどうか
    ///   - completion: コンプリーションハンドラ
    private func shiftBackground(toRight: Bool, completion: (() -> Void)? = nil) {
        // 逆方向時は最初の座標に戻す
        if toRight {
            rotomPokedexTrailingConstraint.isActive = true
            rootViewAndBackgroundLeadingConstraint.constant = initialTableBackgroundX
        } else {
            rotomPokedexTrailingConstraint.isActive = false
            // 背景の中央がスクリーンの中央になるようにずらす
            let screenWidth = UIScreen.main.bounds.width
            let tableBackgroundWidth = self.allTableBackgroundWrapperView.frame.width
            let difference = screenWidth - tableBackgroundWidth
            let newOriginX = difference / 2
            rootViewAndBackgroundLeadingConstraint.constant = newOriginX
        }
        UIView.animate(withDuration: 0.125, animations: { [unowned self] in
            self.view.layoutIfNeeded()
        }, completion: { _ in completion?() })
    }

    /// ビューが表示された
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 安全のためにこちらで送出
        // 複数回走るのでviewModel側でtake(1)しておくこと
        viewDidLoadTrigger.accept(())

        // リストのインセットを設定
        // viewDidLoadではsafeAreaInsetsが取得できないのでこちらで処理
        let tableBottomInset: CGFloat = view.safeAreaInsets.bottom > 0 ? 13 : 5
        pokemonTable.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: tableBottomInset, right: 0)
        pokemonTable.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: tableBottomInset, right: 0)

        // マスクを設定
        // viewDidLoadではサイズがまだ決定されていないのでこちらでやる
        topBar.mask = topBarMaskView

        // リスト背景の初期位置
        // アニメーション後に位置を元に戻せるよう保存しておく
        self.initialTableBackgroundX = self.allTableBackgroundWrapperView.frame.origin.x

        // アニメーション用の背景の制約を作成する
        // 背景のリーディングをテーブルとの相対ではなくルートビューとの相対に変換する
        // (テーブルとの相対にするとテーブルをアニメーションした際につられて背景も動いてしまうため)
        if rootViewAndBackgroundLeadingConstraint == nil {
            // 現在の位置を維持するようにリーディング制約を置き換える
            rootViewAndBackgroundLeadingConstraint = NSLayoutConstraint(
                item: allTableBackgroundWrapperView!,
                attribute: .leading,
                relatedBy: .equal,
                toItem: self.view!,
                attribute: .leading,
                multiplier: 1,
                constant: initialTableBackgroundX
            )
            self.view.addConstraint(rootViewAndBackgroundLeadingConstraint)
        }
    }

    /// 並び替えボタンが押された
    @IBAction func onSortButtonTapped(_ sender: UIButton) {
        // 並び替えボタンのViewControllerをPopoverで出す
        let orderSelectorViewController = OrderSelectorViewController()
        orderSelectorViewController.modalPresentationStyle = .popover
        orderSelectorViewController.preferredContentSize = CGSize(width: 220, height: 125)
        orderSelectorViewController.popoverPresentationController?.sourceView = sender
        orderSelectorViewController.popoverPresentationController?.sourceRect = sender.bounds
        orderSelectorViewController.popoverPresentationController?.permittedArrowDirections = .up
        orderSelectorViewController.popoverPresentationController?.delegate = self
        orderSelectorViewController.delegate = self

        present(orderSelectorViewController, animated: true)
    }

    @IBAction func onScrollToTopButtonTapped(_ sender: UIButton) {
        let topRow = IndexPath(row: 0, section: 0)
        pokemonTable.scrollToRow(at: topRow, at: .top, animated: true)
    }

    @IBAction func onSearchButtonTapped(_ sender: UIButton) {
    }
}

/// ポケモンリストのデリゲート
extension PokemonTableViewController : UITableViewDelegate {

    /// セルの高さ
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54
    }

    /// セルが選択される
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // 現在選択されている行番号(=ひとつ前に選択された行番号)を送出
        previousTappedCell.accept(tableView.indexPathForSelectedRow?.row)
        return indexPath
    }

    /// セルが選択されたとき
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 行番号を送出する
        let selectedRow = indexPath.row
        pokemonTableCellTapped.accept(selectedRow)
    }
}

extension PokemonTableViewController : UIPopoverPresentationControllerDelegate {

    /// Popoverの表示スタイル
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // デフォルトの代わりにnoneを返すことで、iPhoneでもpopover表示ができるようになる
        return .none
    }
}

extension PokemonTableViewController : OrderSelectorViewControllerDelegate {

    /// 並び替えボタンが押された
    func orderSelectorViewController(_ orderSelectorViewController: OrderSelectorViewController, didTouchedButtonOf order: PokemonOrder) {
        // 通知する
        sortButtonTapped.accept(order)
        // Popoverは閉じる
        orderSelectorViewController.dismiss(animated: true, completion: nil)
    }
}
