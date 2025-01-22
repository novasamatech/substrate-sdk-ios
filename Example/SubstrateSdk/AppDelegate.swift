//
//  AppDelegate.swift
//  SubstrateSdk
//
//  Created by ERussel on 07/22/2020.
//  Copyright (c) 2020 ERussel. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let rootContoller = ViewController()

        window = UIWindow()
        window?.rootViewController = rootContoller

        window?.makeKeyAndVisible()

        return true
    }
}
