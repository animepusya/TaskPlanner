//
//  TaskPlannerApp.swift
//  TaskPlanner
//
//  Created by Руслан Меланин on 04.02.2026.
//

import SwiftUI
import CoreData

@main
struct TaskPlannerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
