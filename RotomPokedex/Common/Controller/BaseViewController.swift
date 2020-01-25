//
//  BaseViewController.swift
//  RotomPokedex
//
//  Created by Ryo on 2020/01/04.
//  Copyright © 2020 Ryoga. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {

    /// ホームバーを自動で隠す
    override var prefersHomeIndicatorAutoHidden: Bool {
        return false
    }

    /// ホームバーと通知センターを2回スワイプしないと出てこないようにする
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return [.top, .bottom]
    }
}
