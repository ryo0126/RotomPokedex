//
//  PokemonTableViewCell.swift
//  RotomPokedex
//
//  Created by Ryo on 2019/12/30.
//  Copyright © 2019 Ryoga. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

public class PokemonTableViewCell: UITableViewCell {

    /// 表示するパラメータ
    public struct Parameters {

        /// 小さい右端のスプライト画像の`Observable`
        public let observableSprite: Observable<UIImage>
        /// 図鑑番号
        public let number: Int
        /// ポケモンの名前
        public let name: String
    }

    /// 矢印画像の唯一のインスタンス
    /// 各のセルが一つずつ持つ必要はないのでstaticメンバーにする
    static weak var arrowIndicator: UIImageView!
    /// 矢印がくっつけられているセルインスタンス
    static var cellAttachedToArrowIndicator: PokemonTableViewCell?
    /// 矢印のアニメーション名
    static let arrowIndicatorAnimationName: String = "arrowAnimation"

    @IBOutlet weak var spriteImageView: UIImageView!
    @IBOutlet weak var spriteImageWrapperView: UIView!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var informationButton: UIButton!
    weak var selectedBackground: UIView!

    override public var isSelected: Bool {
        didSet {
            if self.isSelected {

            } else {

            }
        }
    }

    /// スプライト画像の非同期表示用の`Observable`
    private var disposeBag = DisposeBag()

    override public func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        selectionStyle = .none
        selectedBackgroundView = nil
        // ドロップシャドウがカットされないようにclipsToBoundsを切る
        contentView.superview?.clipsToBounds = false
        spriteImageWrapperView.clipsToBounds = false
        spriteImageWrapperView.backgroundColor = .clear
        // 未指定で拡大するとドット絵がぼやけてしまうので.nearestを指定
        spriteImageView.layer.magnificationFilter = .nearest
        spriteImageView.layer.minificationFilter = .nearest

        // セル選択時の背景
        let selectedBackgroundLeft = SelectedCellBackgroundLeft()
        let selectedBackgroundRight = SelectedCellBackgroundRight()
        let selectedBackground = UIView()
        self.selectedBackground = selectedBackground
        selectedBackground.isHidden = false
        selectedBackground.alpha = 0.0
        // 一番後ろに追加する
        insertSubview(selectedBackground, at: 0)

        selectedBackground.addSubview(selectedBackgroundLeft)
        selectedBackground.addSubview(selectedBackgroundRight)
        selectedBackground.snp.makeConstraints { make in
            // スクロールバーに干渉しないよう余白を設ける
            let leftMargin = 12
            make.right.equalTo(informationButton.snp.right).offset(leftMargin)
            make.left.equalTo(spriteImageWrapperView.snp.left)
            make.centerY.equalTo(self.snp.centerY)
            // ラベルの高さより少しだけ高くする
            let multiplier = 1.4
            make.height.equalTo(numberLabel.snp.height).multipliedBy(multiplier)
        }

        selectedBackgroundLeft.snp.makeConstraints { make in
            make.top.equalTo(selectedBackground.snp.top)
            make.right.equalTo(nameLabel.snp.right)
            make.bottom.equalTo(selectedBackground.snp.bottom)
            // 左側に余白を設ける
            let leftMargin = 9
            make.left.equalTo(selectedBackground.snp.left).offset(leftMargin)
        }
        selectedBackgroundRight.snp.makeConstraints { make in
            make.top.equalTo(selectedBackground.snp.top)
            make.right.equalTo(selectedBackground.snp.right)
            make.bottom.equalTo(selectedBackground.snp.bottom)
            make.left.equalTo(nameLabel.snp.left)
        }
        selectedBackground.bringSubviewToFront(selectedBackgroundRight)

        // アニメーション再生管理のためフォアグラウンドエンターを監視しておく
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(viewWillEnterForeground(_:)),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    /// 表示するパラメータを設定する
    /// - Parameter parameters: パラメータ
    public func setParameters(_ parameters: Parameters) {
        numberLabel.text = String(format: "No.%03d", parameters.number)
        nameLabel.text = parameters.name
        // 購読を開始する
        parameters.observableSprite
            .subscribe(onNext: { [weak self] sprite in
                guard let self = self else { return }
                self.spriteImageView.image = sprite
                self.bringSubviewToFront(self.spriteImageView)
                self.bringSubviewToFront(self.spriteImageWrapperView)
            })
            .disposed(by: disposeBag)
    }

    /// 選択状態をセットする
    override public func setSelected(_ selected: Bool, animated: Bool) {
        // 選択された
        if selected {
            changeView(bySelected: true)
            // 矢印マークのアニメーションを開始する
            animateArrowIndicator()
        } else {
            // 解除された場合のみアニメーションする(フェードアウト)
            UIView.animate(withDuration: 0.2, animations: { [weak self] () in
                guard let self = self else { return }
                self.changeView(bySelected: false)
            })
        }
        super.setSelected(selected, animated: animated)
    }

    /// 選択状態に合わせて表示内容を変える
    /// - Parameter bySelected: 表示するかどうか
    private func changeView(bySelected selected: Bool) {
        // 背景を表示する
        selectedBackground.alpha = selected ? 1.0 : 0.0
        // 選択中は文字を白くする
        numberLabel.textColor = selected ? .white: .black
        nameLabel.textColor = selected ? .white: .black
        // ボタンを選択状態にする
        informationButton.isSelected = selected
        // 文字の太字を切り替える
        let numberLabelFontSize = numberLabel.font.pointSize
        let nameLabelFontSize = nameLabel.font.pointSize
        numberLabel.font = selected ? .boldSystemFont(ofSize: numberLabelFontSize) : .systemFont(ofSize: numberLabelFontSize)
        nameLabel.font = selected ? .boldSystemFont(ofSize: nameLabelFontSize) : .systemFont(ofSize: nameLabelFontSize)
    }

    /// 矢印マークの表示を切り替える
    /// - Parameter hidden: 表示するかどうか
    private func animateArrowIndicator() {
        // 矢印がnilなら抜ける
        guard let arrowIndicator = PokemonTableViewCell.arrowIndicator else { return }

        arrowIndicator.isHidden = false
        arrowIndicator.snp.remakeConstraints { make in
            // 高さ固定
            let height = 44
            make.height.equalTo(height)
            // アスペクト比1:1制約
            make.width.equalTo(arrowIndicator.snp.height)

            make.centerY.equalTo(self.snp.centerY)
            // 少しスプライト画像にめり込ませたいのでオフセット
            let rightOffset = 25
            make.right.equalTo(spriteImageWrapperView.snp.left).offset(rightOffset)
        }
        // 制約を反映させる
        superview?.layoutIfNeeded()

        // アニメーション時間
        let duration = 0.7
        // フレーム数
        let frameCount = 30
        // 振幅
        let amplitude = 4

        // 単振動のアニメーションを作成する
        let horizontalAnimation = CAKeyframeAnimation(keyPath: "position.x")
        horizontalAnimation.repeatCount = Float.infinity
        horizontalAnimation.duration = duration
        // 時間は等間隔
        horizontalAnimation.keyTimes = (0...frameCount).map {
            let dividedTime = Double($0) / Double(frameCount)
            return NSNumber(value: Double(dividedTime))
        }
        // 全て再生して1周期となるように設定
        horizontalAnimation.values = (0...frameCount).map {
            let x = CGFloat(amplitude) * sin(CGFloat(2.0 * Double.pi * Double($0) / Double(frameCount)))
            return arrowIndicator.center.x + CGFloat(x)
        }
        arrowIndicator.layer.add(horizontalAnimation, forKey: PokemonTableViewCell.arrowIndicatorAnimationName)

        PokemonTableViewCell.cellAttachedToArrowIndicator = self
    }

    /// アプリがフォアグラウンドにきた
    @objc private func viewWillEnterForeground(_ notification: Notification?) {
        // 選択されているとき
        if isSelected {
            // バックグラウンドに行ったタイミングで矢印マークのアニメーションが削除されてしまうので
            // フォアに戻ってきたときに再設定してやる
            animateArrowIndicator()
        }
    }

    /// 再利用される前の準備
    override public func prepareForReuse() {
        // もし矢印のつけられているセルだったら一旦非表示にする
        if self == .cellAttachedToArrowIndicator {
            PokemonTableViewCell.arrowIndicator?.isHidden = true
        }
        // 間違った画像が遅れて表示されないように前の購読は解除しておく
        disposeBag = DisposeBag()
        // 画像を空にする
        spriteImageView.image = nil
        super.prepareForReuse()
    }

    /// 親ビューに追加された
    override public func didMoveToSuperview() {
        // removeFromSuperview経由であれば抜ける
        guard let superview = self.superview else { return }
        // すでにarrowIndicatorが初期化済みなら無視
        guard PokemonTableViewCell.arrowIndicator == nil else { return }

        // 矢印マーク
        let arrowIndicatorImage = UIImage(named: "Arrow Indicator")
        let arrowIndicator = UIImageView(image: arrowIndicatorImage)
        PokemonTableViewCell.arrowIndicator = arrowIndicator
        arrowIndicator.isHidden = true
        // 画像の縦横比は維持させる
        arrowIndicator.contentMode = .scaleAspectFit
        // 矢印マークを追加
        superview.addSubview(arrowIndicator)
    }
}
