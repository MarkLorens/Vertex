//
//  VertexApp.swift
//  Vertex
//
//  Created by Max on 31/07/26.
//

import SwiftUI
import FirebaseCore

class appDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct VertexApp: App {
    @UIApplicationDelegateAdaptor(appDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
