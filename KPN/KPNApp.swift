//
//  KPNApp.swift
//  KPN
//
//  Created by Ken on 2023-02-19.
//

import SwiftUI

@main
struct KPNApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
