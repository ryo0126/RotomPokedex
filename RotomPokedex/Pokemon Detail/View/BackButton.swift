//
//  BackButton.swift
//  RotomPokedex
//
//  Created by Ryo on 2020/01/04.
//  Copyright © 2020 Ryoga. All rights reserved.
//

import UIKit

class BackButton: UIButton {

    /// 押しやすいように当たり判定を拡大
    override var userInteractiveInsets: UIEdgeInsets {
        let verticalMargin: CGFloat = 20
        let horizontalMargin: CGFloat = 45
        return UIEdgeInsets(top: verticalMargin, left: horizontalMargin, bottom: verticalMargin, right: horizontalMargin)
    }
}
