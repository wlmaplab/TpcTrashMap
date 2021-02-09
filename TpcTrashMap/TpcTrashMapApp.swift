//
//  TpcTrashMapApp.swift
//  TpcTrashMap
//
//  Created by Wei-Cheng Ling on 2021/2/1.
//

import SwiftUI

@main
struct TpcTrashMapApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        LocationProvider.shared.start()
        return true
    }
}
