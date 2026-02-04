//
//  SettingsViewModel.swift
//  TaskPlanner
//

import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var weekStartsOnMonday: Bool {
        didSet {
            UserDefaults.standard.set(weekStartsOnMonday, forKey: Self.weekStartsOnMondayKey)
        }
    }

    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: Self.notificationsEnabledKey)
        }
    }

    private static let weekStartsOnMondayKey = "Settings.weekStartsOnMonday"
    private static let notificationsEnabledKey = "Settings.notificationsEnabled"

    init() {
        let defaults = UserDefaults.standard
        weekStartsOnMonday = defaults.object(forKey: Self.weekStartsOnMondayKey) as? Bool ?? false
        notificationsEnabled = defaults.object(forKey: Self.notificationsEnabledKey) as? Bool ?? true
    }
}

