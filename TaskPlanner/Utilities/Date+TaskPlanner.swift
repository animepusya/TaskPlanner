//
//  Date+TaskPlanner.swift
//  TaskPlanner
//

import Foundation

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? startOfDay(for: date)
    }

    func endOfMonth(for date: Date) -> Date {
        let start = startOfMonth(for: date)
        return self.date(byAdding: DateComponents(month: 1, second: -1), to: start) ?? start
    }
}

extension Date {
    func formattedMonthYear() -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: self)
    }

    func formattedDayTitle() -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "EEE d"
        return formatter.string(from: self)
    }
}

