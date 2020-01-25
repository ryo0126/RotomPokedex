//
//  InformationButton.swift
//  RotomPokedex
//
//  Created by Ryo on 2019/12/31.
//  Copyright © 2019 Ryoga. All rights reserved.
//

import UIKit
import SnapKit

/// 丸い情報ボタン
/// IBからTypeをCustomにして使う
public class InformationButton: UIButton {

    public var normalBackgroundColor: UIColor = .clear
    public var selectedBackgroundColor: UIColor = .white
    public var highlightedBackgroundColor: UIColor = .gray

    public var normalTitleColor: UIColor = .clear
    public var selectedTitleColor: UIColor = .black
    public var highlightedTitleColor: UIColor = .black

    /// 選択されているかどうか
    override public var isSelected: Bool {
        // 状態に合わせて背景色を変更する
        didSet {
            backgroundView.backgroundColor = self.isSelected ? selectedBackgroundColor : normalBackgroundColor
            tintColor = self.isSelected ? selectedTitleColor : normalTitleColor
        }
    }

    /// 押されているかどうか
    override public var isHighlighted: Bool {
        // 状態に合わせて背景色を変更する
        didSet {
            if isSelected {
                backgroundView.backgroundColor = self.isHighlighted ? highlightedBackgroundColor : selectedBackgroundColor
                tintColor = self.isHighlighted ? highlightedTitleColor : normalTitleColor
            } else {
                backgroundView.backgroundColor = self.isHighlighted ? highlightedBackgroundColor : normalBackgroundColor
                tintColor = self.isHighlighted ? highlightedTitleColor : selectedTitleColor
            }
        }
    }

    /// 丸い背景
    private var backgroundView: UIView!

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear
        backgroundView = UIView()
        backgroundView.backgroundColor = normalBackgroundColor
        backgroundView.layer.masksToBounds = true
        tintColor = normalTitleColor
    }

    /// 親ビューに追加されたとき
    override public func didMoveToSuperview() {
        // removeFromSuperview経由で呼ばれるとsuperviewがnilなのでガード
        guard let superview = self.superview else { return }
        // 背景を親ビューに追加
        // 背景にしたいので一番後ろに追加
        superview.insertSubview(backgroundView, at: 0)
        // 背景の円はすこし大きくしたいのでインセットをつける
        let margin: CGFloat = 5
        let horizontalOffset:CGFloat = -1
        let insets = UIEdgeInsets(top: -margin, left: -margin + horizontalOffset, bottom: margin, right: margin + horizontalOffset)
        backgroundView.fit(toView: self, withInsets: insets)
    }

    /// 親ビューから削除されたとき
    override public func removeFromSuperview() {
        // 背景を親ビューから外しておく
        backgroundView.removeFromSuperview()
        // 制約もリセット
        backgroundView.snp.removeConstraints()
        super.removeFromSuperview()
    }

    /// サブビューを描画するとき
    override public func layoutSubviews() {
        // 現在の大きさでちょうど正円になるよう半径を指定する
        let buttonWidth = backgroundView.bounds.width
        backgroundView.layer.cornerRadius = buttonWidth / 2
        super.layoutSubviews()
    }
}
