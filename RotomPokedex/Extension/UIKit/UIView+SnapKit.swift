//
//  UIView+SnapKit.swift
//  RotomPokedex
//
//  Created by Ryo on 2020/01/01.
//  Copyright © 2020 Ryoga. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

extension UIView {

    /// 対象のビューに四辺をピッタリくっつける制約を付加する
    /// - Parameters:
    ///   - toView: 対象のビュー
    ///   - withInsets: 四辺に対するオフセット
    public func fit(toView view: UIView, withInsets insets: UIEdgeInsets? = nil) {
        if let insets = insets {
            self.snp.makeConstraints { make in
                make.top.equalTo(view.snp.top).offset(insets.top)
                make.right.equalTo(view.snp.right).offset(insets.right)
                make.bottom.equalTo(view.snp.bottom).offset(insets.bottom)
                make.left.equalTo(view.snp.left).offset(insets.left)
            }
        } else {
            self.snp.makeConstraints { make in
                make.top.equalTo(view.snp.top)
                make.right.equalTo(view.snp.right)
                make.bottom.equalTo(view.snp.bottom)
                make.left.equalTo(view.snp.left)
            }
        }
    }

    /// 親ビューに四辺をピッタリくっつける制約を付加する
    /// 親ビューがいない場合は`nil`で落ちる
    ///  - Parameter withInsets: 四辺に対するオフセット
    public func fitToSuperview(withInsets insets: UIEdgeInsets? = nil) {
        self.fit(toView: self.superview!, withInsets: insets)
    }
}
