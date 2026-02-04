//
//  TimeInterval+Formatting.swift
//  TaskPlanner
//

import Foundation

extension TimeInterval {
    func formattedHoursMinutes() -> String {
        let totalMinutes = Int((self / 60.0).rounded(.down))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }
}

