//
//  Persistence.swift
//  TaskPlanner
//
//  Created by Руслан Меланин on 04.02.2026.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TaskPlanner")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true

        if !inMemory {
            seedTasksIfNeeded(context: container.viewContext)
        }
    }
}

// MARK: - Seeding

private extension PersistenceController {
    static let hasSeededTasksKey = "hasSeededTasks_v1"

    func seedTasksIfNeeded(context: NSManagedObjectContext) {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: Self.hasSeededTasksKey) == false else { return }

        context.perform {
            self.insertSeedTasks(into: context)
            do {
                try context.save()
                defaults.set(true, forKey: Self.hasSeededTasksKey)
            } catch {
                // If save fails, do not set the flag so we can try again next launch.
                assertionFailure("Seeding failed: \(error)")
            }
        }
    }

    func insertSeedTasks(into context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? calendar.startOfDay(for: now)

        func makeDate(dayOffset: Int, hour: Int, minute: Int) -> Date {
            let base = calendar.date(byAdding: .day, value: dayOffset, to: monthStart) ?? monthStart
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        }

        func dayDate(_ date: Date) -> Date {
            calendar.startOfDay(for: date)
        }

        struct Seed {
            let title: String
            let details: String?
            let category: String
            let colorTag: String
            let repeatRule: String
            let dayOffset: Int
            let startH: Int
            let startM: Int
            let endH: Int
            let endM: Int
        }

        let seeds: [Seed] = [
            .init(title: "Team standup", details: "Daily sync with the team", category: "Work", colorTag: "purple", repeatRule: "daily", dayOffset: 0, startH: 9, startM: 30, endH: 10, endM: 0),
            .init(title: "Deep work session", details: "Focus block: planning + coding", category: "Work", colorTag: "blue", repeatRule: "none", dayOffset: 1, startH: 11, startM: 0, endH: 13, endM: 0),
            .init(title: "Study SwiftUI", details: "Animations and custom shapes", category: "Study", colorTag: "green", repeatRule: "weekly", dayOffset: 2, startH: 18, startM: 0, endH: 19, endM: 15),
            .init(title: "Gym", details: "Leg day", category: "Hobby", colorTag: "red", repeatRule: "none", dayOffset: 3, startH: 19, startM: 30, endH: 20, endM: 30),
            .init(title: "Read a book", details: "20 pages", category: "Hobby", colorTag: "pink", repeatRule: "daily", dayOffset: 4, startH: 21, startM: 0, endH: 21, endM: 30),
            .init(title: "Review notes", details: "Summarize key points", category: "Study", colorTag: "yellow", repeatRule: "none", dayOffset: 6, startH: 8, startM: 15, endH: 8, endM: 45),
            .init(title: "Design tasks for the week", details: "Prioritize top 3 outcomes", category: "Work", colorTag: "purple", repeatRule: "weekly", dayOffset: 7, startH: 10, startM: 0, endH: 11, endM: 0),
            .init(title: "Language practice", details: "30 minutes", category: "Study", colorTag: "blue", repeatRule: "daily", dayOffset: 9, startH: 7, startM: 30, endH: 8, endM: 0)
        ]

        for seed in seeds {
            let start = makeDate(dayOffset: seed.dayOffset, hour: seed.startH, minute: seed.startM)
            let end = makeDate(dayOffset: seed.dayOffset, hour: seed.endH, minute: seed.endM)

            let task = TaskEntity(context: context)
            task.id = UUID()
            task.title = seed.title
            task.details = seed.details
            task.category = seed.category
            task.colorTag = seed.colorTag
            task.repeatRule = seed.repeatRule
            task.isDone = false
            task.createdAt = now
            task.startTime = start
            task.endTime = end
            task.dayDate = dayDate(start)
        }
    }
}
