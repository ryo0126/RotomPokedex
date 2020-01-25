//
//  TopBarButton.swift
//  RotomPokedex
//
//  Created by Ryo on 2020/01/04.
//  Copyright © 2020 Ryoga. All rights reserved.
//

import UIKit

class TopBarButton: UIButton {

    /// 押しやすいように当たり判定を拡大
    override var userInteractiveInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
}
