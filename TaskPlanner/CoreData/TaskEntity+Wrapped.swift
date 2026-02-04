//
//  TaskEntity+Wrapped.swift
//  TaskPlanner
//

import Foundation

extension TaskEntity {
    var wId: UUID { id ?? UUID() }
    var wTitle: String { title ?? "" }
    var wDetails: String { details ?? "" }

    var wDayDate: Date { dayDate ?? Calendar.current.startOfDay(for: Date()) }
    var wStartTime: Date { startTime ?? Date() }
    var wEndTime: Date { endTime ?? Date() }

    var wCategory: String { category ?? "Work" }
    var wColorTag: String { colorTag ?? "purple" }
    var wRepeatRule: String { repeatRule ?? "none" }

    var wIsDone: Bool { isDone }
    var wCreatedAt: Date { createdAt ?? Date() }
}

