//
//  UIButton.swift
//  RotomPokedex
//
//  Created by Ryo on 2020/01/04.
//  Copyright © 2020 Ryoga. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {

    /// ボタンの当たり判定の拡大分
    @objc open var userInteractiveInsets: UIEdgeInsets {
        return .zero
    }

    /// ボタンの当たり判定
    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // useruserInteractiveInsetsの分だけ拡大する
        let insets = userInteractiveInsets
        var rect = bounds
        rect.origin.x -= insets.left
        rect.origin.y -= insets.top
        rect.size.width += insets.left + insets.right
        rect.size.height += insets.top + insets.bottom

        // 拡大した領域に含まれているかどうかで判定する
        return rect.contains(point)
    }
}
