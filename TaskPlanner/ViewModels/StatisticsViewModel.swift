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

        // ✅ IMPORTANT:
        // - Tasks inside month
        // - PLUS repeating tasks created before monthStart, as long as dayDate <= monthEnd
        request.predicate = NSPredicate(
            format: "(dayDate >= %@ AND dayDate <= %@) OR (repeatRule != %@ AND dayDate <= %@)",
            monthStart as NSDate,
            monthEnd as NSDate,
            "none",
            monthEnd as NSDate
        )

        request.sortDescriptors = [
            NSSortDescriptor(key: "dayDate", ascending: true),
            NSSortDescriptor(key: "startTime", ascending: true)
        ]

        do {
            let fetched = try context.fetch(request)
            monthTasks = fetched
            recomputeStats(from: fetched, monthStart: monthStart, monthEnd: monthEnd)
        } catch {
            monthTasks = []
            categoryStats = []
            totalSeconds = 0
            assertionFailure("Failed to fetch statistics month tasks: \(error)")
        }
    }

    private func recomputeStats(from tasks: [TaskEntity], monthStart: Date, monthEnd: Date) {
        var byCategory: [String: (seconds: TimeInterval, colorTag: String)] = [:]
        var total: TimeInterval = 0

        let monthStartDay = calendar.startOfDay(for: monthStart)
        let monthEndDay = calendar.startOfDay(for: monthEnd)

        for t in tasks {
            let duration = validDurationSeconds(for: t)
            guard duration > 0 else { continue }

            let occurrences = occurrencesInDisplayedMonth(for: t, monthStart: monthStartDay, monthEnd: monthEndDay)
            guard occurrences > 0 else { continue }

            let contribution = duration * TimeInterval(occurrences)

            total += contribution
            let key = t.wCategory
            let existing = byCategory[key] ?? (0, t.wColorTag)
            byCategory[key] = (existing.seconds + contribution, existing.colorTag)
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

// MARK: - Repeat occurrences logic (month-only, no Core Data duplication)

private extension StatisticsViewModel {

    func validDurationSeconds(for task: TaskEntity) -> TimeInterval {
        let start = task.wStartTime
        let end = task.wEndTime
        let duration = end.timeIntervalSince(start)
        return max(0, duration)
    }

    func occurrencesInDisplayedMonth(for task: TaskEntity, monthStart: Date, monthEnd: Date) -> Int {
        let baseDay = calendar.startOfDay(for: task.wDayDate)

        // Never count before task was created
        guard baseDay <= monthEnd else { return 0 }

        let rule = task.wRepeatRule.lowercased()

        switch rule {
        case "none":
            return (baseDay >= monthStart && baseDay <= monthEnd) ? 1 : 0

        case "daily":
            // count days in [max(baseDay, monthStart) ... monthEnd]
            let from = max(baseDay, monthStart)
            return inclusiveDayCount(from: from, to: monthEnd)

        case "weekly":
            let from = max(baseDay, monthStart)
            let targetWeekday = calendar.component(.weekday, from: baseDay)
            return weeklyOccurrenceCount(weekday: targetWeekday, from: from, to: monthEnd)

        case "monthly":
            // Once per month: same day-of-month, only if that date exists in this month and >= baseDay
            return monthlyOccurrenceCount(baseDay: baseDay, monthStart: monthStart, monthEnd: monthEnd)

        default:
            // Unknown rule -> treat as none (safe fallback)
            return (baseDay >= monthStart && baseDay <= monthEnd) ? 1 : 0
        }
    }

    func inclusiveDayCount(from: Date, to: Date) -> Int {
        guard from <= to else { return 0 }
        let days = calendar.dateComponents([.day], from: from, to: to).day ?? 0
        return max(0, days + 1)
    }

    func weeklyOccurrenceCount(weekday targetWeekday: Int, from: Date, to: Date) -> Int {
        guard from <= to else { return 0 }

        let fromWeekday = calendar.component(.weekday, from: from)
        let delta = (targetWeekday - fromWeekday + 7) % 7

        guard let first = calendar.date(byAdding: .day, value: delta, to: from) else { return 0 }
        if first > to { return 0 }

        let daysBetween = calendar.dateComponents([.day], from: first, to: to).day ?? 0
        return 1 + max(0, daysBetween / 7)
    }

    func monthlyOccurrenceCount(baseDay: Date, monthStart: Date, monthEnd: Date) -> Int {
        let baseDayOfMonth = calendar.component(.day, from: baseDay)

        // does this displayed month contain that day?
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 0
        guard baseDayOfMonth >= 1, baseDayOfMonth <= daysInMonth else { return 0 }

        var comps = calendar.dateComponents([.year, .month], from: monthStart)
        comps.day = baseDayOfMonth

        guard let occurrence = calendar.date(from: comps) else { return 0 }
        let occurrenceDay = calendar.startOfDay(for: occurrence)

        guard occurrenceDay >= monthStart, occurrenceDay <= monthEnd else { return 0 }
        guard occurrenceDay >= baseDay else { return 0 }

        return 1
    }
}


