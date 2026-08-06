//
//  VertexApp.swift
//  Vertex
//
//  Created by Max on 31/07/26.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

extension Services {
    /// The composition root — the one place that knows Firebase exists.
    static var live: Services {
        let repository = FirestoreEventRepository()
        return Services(auth: FirebaseAuthService(), events: repository, directory: repository)
    }
}

@main
struct VertexApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            RootView(services: .live)
        }
    }
}
