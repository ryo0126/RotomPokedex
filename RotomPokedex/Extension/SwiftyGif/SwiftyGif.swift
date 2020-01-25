//
//  SwiftyGif.swift
//  RotomPokedex
//
//  Created by Ryo on 2020/01/12.
//  Copyright © 2020 Ryoga. All rights reserved.
//

import Foundation
import SnapKit
import SwiftyGif

extension UIImageView {

    /// セットされているGIF画像をクリアする
    public func clearGifImage() {
        self.setImage(UIImage())
    }

    /// この`UIImageView`をセットされているGIF画像の整数倍に設定する
    /// - Parameter scale: 倍率
    public func setGifScale(_ scale: CGFloat) {
        let rawWidth = self.frameAtIndex(index: 0).size.width
        let rawHeight = self.frameAtIndex(index: 0).size.height
        let newWidth = scale * rawWidth
        let newHeight = scale * rawHeight
        self.snp.updateConstraints { update in
            update.width.equalTo(newWidth)
            update.height.equalTo(newHeight)
        }
    }
}
