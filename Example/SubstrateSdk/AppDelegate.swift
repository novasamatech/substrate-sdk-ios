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


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        let rootContoller = ViewController()

        window = UIWindow()
        window?.rootViewController = rootContoller

        window?.makeKeyAndVisible()

        return true
    }
}

