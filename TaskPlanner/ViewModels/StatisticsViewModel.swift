//
//  StatisticsViewModel.swift
//  TaskPlanner
//

import Combine
import CoreData
import Foundation

struct CategoryStat: Identifiable, Hashable {
    let id: String
    let name: String
    let seconds: TimeInterval
    let colorTag: String

    var hours: Double { seconds / 3600.0 }
}

@MainActor
final class StatisticsViewModel: ObservableObject {
    @Published var displayedMonth: Date
    @Published private(set) var monthTasks: [TaskEntity] = []

    @Published private(set) var categoryStats: [CategoryStat] = []
    @Published private(set) var totalSeconds: TimeInterval = 0

    private var context: NSManagedObjectContext?
    private let calendar: Calendar

    init(calendar: Calendar = .current, now: Date = Date()) {
        self.calendar = calendar
        self.displayedMonth = calendar.startOfMonth(for: now)
    }

    func configure(context: NSManagedObjectContext) {
        guard self.context == nil else { return }
        self.context = context
        refreshMonth()
    }

    func goToPreviousMonth() {
        displayedMonth = calendar.startOfMonth(for: calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth)
        refreshMonth()
    }

    func goToNextMonth() {
        displayedMonth = calendar.startOfMonth(for: calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth)
        refreshMonth()
    }

    func refreshMonth() {
        guard let context else { return }
        let monthStart = calendar.startOfMonth(for: displayedMonth)
        let monthEnd = calendar.endOfMonth(for: displayedMonth)

        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "dayDate >= %@ AND dayDate <= %@", monthStart as NSDate, monthEnd as NSDate)
        request.sortDescriptors = [
            NSSortDescriptor(key: "dayDate", ascending: true),
            NSSortDescriptor(key: "startTime", ascending: true)
        ]

        do {
            let fetched = try context.fetch(request)
            monthTasks = fetched
            recomputeStats(from: fetched)
        } catch {
            monthTasks = []
            categoryStats = []
            totalSeconds = 0
            assertionFailure("Failed to fetch statistics month tasks: \(error)")
        }
    }

    private func recomputeStats(from tasks: [TaskEntity]) {
        var byCategory: [String: (seconds: TimeInterval, colorTag: String)] = [:]
        var total: TimeInterval = 0

        for t in tasks {
            let start = t.wStartTime
            let end = t.wEndTime
            let duration = end.timeIntervalSince(start)
            guard duration > 0 else { continue }

            total += duration
            let key = t.wCategory
            let existing = byCategory[key] ?? (0, t.wColorTag)
            byCategory[key] = (existing.seconds + duration, existing.colorTag)
        }

        totalSeconds = total

        // Preferred ordering per spec
        let order = ["Work", "Study", "Hobby"]
        let stats = byCategory.map { (key, value) in
            CategoryStat(id: key, name: key, seconds: value.seconds, colorTag: value.colorTag)
        }

        categoryStats = stats.sorted {
            let li = order.firstIndex(of: $0.name) ?? 999
            let ri = order.firstIndex(of: $1.name) ?? 999
            if li != ri { return li < ri }
            return $0.seconds > $1.seconds
        }
    }

    func percent(for stat: CategoryStat) -> Double {
        guard totalSeconds > 0 else { return 0 }
        return stat.seconds / totalSeconds
    }
}

