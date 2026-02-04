//
//  SettingsView.swift
//  TaskPlanner
//

import CoreData
import SwiftUI

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = SettingsViewModel()
    @State private var showClearAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    preferencesSection
                    dataSection
                    aboutSection
                }
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.top, DS.Spacing.lg)
                .padding(.bottom, 24)
            }
            .background(DS.ColorToken.appBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(DS.ColorToken.textSecondary)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close Settings")
                }
            }
            .alert("Clear all tasks", isPresented: $showClearAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    clearAllTasks()
                }
            } message: {
                Text("This will permanently delete all tasks. This action cannot be undone.")
            }
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("Preferences")
                .font(DS.Typography.sectionTitle)
                .foregroundColor(DS.ColorToken.textPrimary)

            VStack(spacing: 12) {
                Toggle(isOn: $viewModel.weekStartsOnMonday) {
                    Text("Week starts on Monday")
                        .font(DS.Typography.body)
                        .foregroundColor(DS.ColorToken.textPrimary)
                }
                .toggleStyle(SwitchToggleStyle(tint: DS.ColorToken.purple))

                /*
                Toggle(isOn: $viewModel.notificationsEnabled) {
                    Text("Enable notifications")
                        .font(DS.Typography.body)
                        .foregroundColor(DS.ColorToken.textPrimary)
                }
                .toggleStyle(SwitchToggleStyle(tint: DS.ColorToken.purple))
                */
            }
        }
        .dsCard()
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("Data")
                .font(DS.Typography.sectionTitle)
                .foregroundColor(DS.ColorToken.textPrimary)

            Button {
                showClearAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                    Text("Clear all tasks")
                        .font(DS.Typography.body)
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
        .dsCard()
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("About")
                .font(DS.Typography.sectionTitle)
                .foregroundColor(DS.ColorToken.textPrimary)

            VStack(alignment: .leading, spacing: 4) {
                Text("TaskPlanner")
                    .font(DS.Typography.body)
                    .foregroundColor(DS.ColorToken.textPrimary)
                Text("iOS 15+")
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.ColorToken.textSecondary)
                Text("Built with SwiftUI and Core Data.")
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.ColorToken.textSecondary)
                    .padding(.top, 4)
            }
        }
        .dsCard()
    }

    private func clearAllTasks() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TaskEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs

        do {
            let result = try viewContext.execute(deleteRequest) as? NSBatchDeleteResult
            if let objectIDs = result?.result as? [NSManagedObjectID], !objectIDs.isEmpty {
                let changes: [AnyHashable: Any] = [
                    NSDeletedObjectsKey: objectIDs
                ]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [viewContext])
            }
            try viewContext.save()
        } catch {
            assertionFailure("Failed to clear all tasks: \(error)")
        }
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

