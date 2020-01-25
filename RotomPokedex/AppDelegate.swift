//
//  AppDelegate.swift
//  RotomPokédex
//
//  Created by Ryo on 2019/12/29.
//  Copyright © 2019 Ryoga. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = LaunchScreenViewController()
        window?.makeKeyAndVisible()

        return true
    }
}

