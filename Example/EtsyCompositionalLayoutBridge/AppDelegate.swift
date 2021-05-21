//
//  AppDelegate.swift
//  EtsyCompositionalLayoutBridgeDemo
//
//  Created by Sharar Rahman on 5/19/21.
//  Copyright © 2021 Etsy. All rights reserved.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = DemoViewController()
        window.makeKeyAndVisible()
        self.window = window

        return true
    }
}

