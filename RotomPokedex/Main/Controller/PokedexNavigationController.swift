//
//  PokedexNavigationController.swift
//  RotomPokedex
//
//  Created by Ryo on 2019/12/31.
//  Copyright © 2019 Ryoga. All rights reserved.
//

import UIKit

class PokedexNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = true
    }
}
