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

    private var context: NSManagedObjectContext?
    private let calendar: Calendar

    init(calendar: Calendar = .current, now: Date = Date()) {
        self.calendar = calendar
        let monthStart = calendar.startOfMonth(for: now)
        self.displayedMonth = monthStart
        self.selectedDay = calendar.startOfDay(for: now)
    }

    func configure(context: NSManagedObjectContext) {
        guard self.context == nil else { return }
        self.context = context
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
            taskCountByDay = Dictionary(grouping: fetched, by: { calendar.startOfDay(for: $0.wDayDate) })
                .mapValues { $0.count }

            // If the selected day is outside the displayed month, snap it to month start.
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
            .filter { calendar.startOfDay(for: $0.wDayDate) == dayKey }
            .sorted { $0.wStartTime < $1.wStartTime }
    }
}

