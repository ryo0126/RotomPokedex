//
//  SelectedCellBackground.swift
//  RotomPokedex
//
//  Created by Ryo on 2019/12/30.
//  Copyright © 2019 Ryoga. All rights reserved.
//

import UIKit
import SnapKit

/// 選択されたセルの左側の背景
class SelectedCellBackgroundLeft: UIView {

    /// 背景
    weak var backgroundView: UIView!

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    /// IBからは使わない
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        clipsToBounds = false
        let backgroundView = UIView()
        self.backgroundView = backgroundView
        backgroundView.backgroundColor = .selectedCellOrange
        backgroundView.clipsToBounds = false
        backgroundView.layer.masksToBounds = false
        backgroundView.layer.shadowColor = UIColor.black.cgColor
        backgroundView.layer.shadowOffset = CGSize(width: 0, height: 3)
        backgroundView.layer.shadowRadius = 5
        backgroundView.layer.shadowOpacity = 0.4
        // 左側なので左側の角だけ丸角にしておく
        backgroundView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]

        self.addSubview(backgroundView)
        backgroundView.fitToSuperview()
    }
    
    /// サブビューを描画するとき
    override func layoutSubviews() {
        // 現在の高さから自然な丸角半径を指定
        let currentHeight = self.bounds.height
        backgroundView.layer.cornerRadius = currentHeight / 2
        super.layoutSubviews()
    }
}

/// 選択されたセルの右側の背景
class SelectedCellBackgroundRight: UIView {

    /// 左端の台形部分
    weak var trapezium: UIView!
    /// 背景
    weak var backgroundView: UIView!

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    /// IBからは使わない
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        clipsToBounds = false
        let backgroundView = UIView()
        self.backgroundView = backgroundView
        backgroundView.backgroundColor = .black
        backgroundView.clipsToBounds = false
        backgroundView.layer.masksToBounds = false
        backgroundView.layer.shadowColor = UIColor.black.cgColor
        backgroundView.layer.shadowOffset = CGSize(width: 0, height: 1)
        backgroundView.layer.shadowRadius = 5
        backgroundView.layer.shadowOpacity = 0.3
        // 右側なので右側の角だけ丸角にしておく
        backgroundView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]

        let triangleView = Trapezium()
        self.trapezium = triangleView
        triangleView.fillColor = .black

        self.addSubview(triangleView)
        self.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.top.equalTo(self.snp.top)
            make.right.equalTo(self.snp.right)
            make.bottom.equalTo(self.snp.bottom)
        }
        triangleView.snp.makeConstraints { make in
            // 高さと幅をそろえる(アスペクト比1:1制約)
            make.height.equalTo(self.snp.height)
            make.width.equalTo(triangleView.snp.height)
            make.right.equalTo(backgroundView.snp.left)
            // 左側が欠けてる分ピッタリくっつけると幅が狭く見えるので、少し左側にオフセットする
            let leftPadding = 11
            make.left.equalTo(self.snp.left).offset(-leftPadding)
            make.centerY.equalTo(self.snp.centerY)
        }
    }

    /// サブビューを描画するとき
    override func layoutSubviews() {
        // 現在の高さから自然な丸角半径を指定
        let currentHeight = self.bounds.height
        backgroundView.layer.cornerRadius = currentHeight / 2
        super.layoutSubviews()
    }
}
