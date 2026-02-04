//
//  PlannerViewModel.swift
//  TaskPlanner
//

import Combine
import CoreData
import Foundation

@MainActor
final class PlannerViewModel: ObservableObject {
    @Published var displayedMonth: Date
    @Published var selectedDay: Date

    @Published private(set) var monthTasks: [TaskEntity] = []
    @Published private(set) var dayTasks: [TaskEntity] = []
    @Published private(set) var taskCountByDay: [Date: Int] = [:] // key: startOfDay

    // ✅ NEW: expose setting to the view
    @Published private(set) var weekStartsOnMonday: Bool = false

    private var context: NSManagedObjectContext?
    private let calendar: Calendar

    // Keep key local (no architecture changes / no shared state)
    private static let weekStartsOnMondayKey = "Settings.weekStartsOnMonday"

    init(calendar: Calendar = .current, now: Date = Date()) {
        self.calendar = calendar
        let monthStart = calendar.startOfMonth(for: now)
        self.displayedMonth = monthStart
        self.selectedDay = calendar.startOfDay(for: now)

        // ✅ initial load
        reloadWeekStartSetting()
    }

    // ✅ NEW: re-read defaults when needed
    func reloadWeekStartSetting() {
        weekStartsOnMonday = UserDefaults.standard.object(forKey: Self.weekStartsOnMondayKey) as? Bool ?? false
    }

    func configure(context: NSManagedObjectContext) {
        guard self.context == nil else { return }
        self.context = context

        // ✅ acceptable per constraints
        reloadWeekStartSetting()
        refreshMonth()
    }

    func goToPreviousMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
        displayedMonth = calendar.startOfMonth(for: displayedMonth)
        refreshMonth()
    }

    func goToNextMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
        displayedMonth = calendar.startOfMonth(for: displayedMonth)
        refreshMonth()
    }

    func selectDay(_ date: Date) {
        selectedDay = calendar.startOfDay(for: date)
        refreshSelectedDay()
    }

    func refreshMonth() {
        guard let context else { return }

        // ✅ acceptable per constraints
        reloadWeekStartSetting()

        let monthStart = calendar.startOfMonth(for: displayedMonth)
        let monthEnd = calendar.endOfMonth(for: displayedMonth)

        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")

        // ✅ IMPORTANT:
        // - Non-repeating tasks: only those inside current month
        // - Repeating tasks: include those created before monthStart, as long as dayDate <= monthEnd
        // (so they can "project" into this month)
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

            // ✅ Recompute indicators for every day in displayed month using repeat rules
            taskCountByDay = makeTaskCountByDay(monthStart: monthStart, monthEnd: monthEnd, tasks: fetched)

            if !calendar.isDate(selectedDay, equalTo: monthStart, toGranularity: .month) {
                selectedDay = calendar.startOfDay(for: monthStart)
            }
            refreshSelectedDay()
        } catch {
            monthTasks = []
            dayTasks = []
            taskCountByDay = [:]
            assertionFailure("Failed to fetch month tasks: \(error)")
        }
    }

    func refreshSelectedDay() {
        let dayKey = calendar.startOfDay(for: selectedDay)

        dayTasks = monthTasks
            .filter { occurs($0, on: dayKey) }
            .sorted { taskTimeSortKey($0.wStartTime) < taskTimeSortKey($1.wStartTime) }
    }
}

// MARK: - Repeat logic (MVP, no Core Data duplication)

private extension PlannerViewModel {

    func occurs(_ task: TaskEntity, on day: Date) -> Bool {
        let targetDay = calendar.startOfDay(for: day)
        let baseDay = calendar.startOfDay(for: task.wDayDate)

        // never show before task was created
        guard targetDay >= baseDay else { return false }

        switch task.wRepeatRule.lowercased() {
        case "none":
            return calendar.isDate(targetDay, inSameDayAs: baseDay)

        case "daily":
            return true // already ensured targetDay >= baseDay

        case "weekly":
            let baseWeekday = calendar.component(.weekday, from: baseDay)
            let targetWeekday = calendar.component(.weekday, from: targetDay)
            return baseWeekday == targetWeekday

        case "monthly":
            let baseDayOfMonth = calendar.component(.day, from: baseDay)
            let targetDayOfMonth = calendar.component(.day, from: targetDay)
            return baseDayOfMonth == targetDayOfMonth

        default:
            // Unknown rule -> treat as none (safe fallback)
            return calendar.isDate(targetDay, inSameDayAs: baseDay)
        }
    }

    func makeTaskCountByDay(monthStart: Date, monthEnd: Date, tasks: [TaskEntity]) -> [Date: Int] {
        let dayCount = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        var result: [Date: Int] = [:]
        result.reserveCapacity(dayCount)

        for offset in 0..<dayCount {
            guard let day = calendar.date(byAdding: .day, value: offset, to: monthStart) else { continue }
            let key = calendar.startOfDay(for: day)

            let count = tasks.reduce(0) { partial, task in
                partial + (occurs(task, on: key) ? 1 : 0)
            }
            if count > 0 {
                result[key] = count
            }
        }

        return result
    }

    // Sort by time-of-day only (because repeating tasks keep original date component in startTime)
    func taskTimeSortKey(_ date: Date) -> Int {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        let h = comps.hour ?? 0
        let m = comps.minute ?? 0
        return h * 60 + m
    }
}



