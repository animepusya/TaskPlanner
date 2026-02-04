//
//  TaskEditorViewModel.swift
//  TaskPlanner
//

import Combine
import CoreData
import Foundation

enum TaskEditorMode: Equatable {
    case create
    case edit(TaskEntity)

    var title: String {
        switch self {
        case .create: return "Create Task"
        case .edit: return "Edit Task"
        }
    }
}

@MainActor
final class TaskEditorViewModel: ObservableObject {
    @Published var taskName: String = ""
    @Published var category: String = "Work"
    @Published var dayDate: Date = Calendar.current.startOfDay(for: Date())
    @Published var startTime: Date = Date()
    @Published var endTime: Date = Date().addingTimeInterval(60 * 60)
    @Published var colorTag: String = "purple"
    @Published var repeatRule: String = "none"
    @Published var notes: String = ""

    @Published var showValidationError = false
    @Published var validationMessage: String = ""

    let mode: TaskEditorMode

    let categories = ["Work", "Study", "Hobby"]
    let repeatRules = ["none", "daily", "weekly", "monthly"]
    let colorTags = ["blue", "purple", "pink", "red", "yellow", "green"]

    init(mode: TaskEditorMode, now: Date = Date()) {
        self.mode = mode

        switch mode {
        case .create:
            let cal = Calendar.current
            let day = cal.startOfDay(for: now)
            dayDate = day
            startTime = cal.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? now
            endTime = cal.date(bySettingHour: 10, minute: 0, second: 0, of: day) ?? now.addingTimeInterval(60 * 60)
        case .edit(let task):
            taskName = task.wTitle
            category = task.wCategory
            dayDate = Calendar.current.startOfDay(for: task.wDayDate)
            startTime = task.wStartTime
            endTime = task.wEndTime
            colorTag = task.wColorTag
            repeatRule = task.wRepeatRule
            notes = task.wDetails
        }
    }

    func syncTimesToSelectedDay() {
        startTime = aligned(time: startTime, toDay: dayDate)
        endTime = aligned(time: endTime, toDay: dayDate)
    }

    func aligned(time: Date, toDay day: Date) -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: time)
        return cal.date(bySettingHour: comps.hour ?? 0, minute: comps.minute ?? 0, second: 0, of: day) ?? day
    }

    func validate() -> Bool {
        let trimmed = taskName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationMessage = "Task name can’t be empty."
            showValidationError = true
            return false
        }
        guard endTime > startTime else {
            validationMessage = "End time must be after start time."
            showValidationError = true
            return false
        }
        showValidationError = false
        validationMessage = ""
        return true
    }
}

