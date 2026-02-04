//
//  TaskDetailsView.swift
//  TaskPlanner
//

import SwiftUI

struct TaskDetailsView: View {
    let task: TaskEntity

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.wTitle)
                        .font(DS.Typography.title)
                        .foregroundColor(DS.ColorToken.textPrimary)

                    Text(task.wCategory)
                        .font(DS.Typography.subtitle)
                        .foregroundColor(DS.ColorToken.textSecondary)
                }

                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    infoRow(icon: "calendar", label: "Date", value: task.wDayDate.formatted(date: .abbreviated, time: .omitted))
                    infoRow(icon: "clock", label: "Time", value: "\(task.wStartTime.formatted(date: .omitted, time: .shortened)) – \(task.wEndTime.formatted(date: .omitted, time: .shortened))")
                    infoRow(icon: "repeat", label: "Repeat", value: task.wRepeatRule)
                    infoRow(icon: "paintpalette", label: "Color", value: task.wColorTag)
                    infoRow(icon: task.wIsDone ? "checkmark.circle.fill" : "circle", label: "Status", value: task.wIsDone ? "Done" : "Not done")
                }
                .dsCard()

                if !task.wDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(DS.Typography.sectionTitle)
                            .foregroundColor(DS.ColorToken.textPrimary)
                        Text(task.wDetails)
                            .font(DS.Typography.body)
                            .foregroundColor(DS.ColorToken.textSecondary)
                    }
                    .dsCard()
                }

                Text("Task Details actions (Edit/Delete/Done) will be implemented next.")
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.ColorToken.textSecondary)
            }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.top, DS.Spacing.lg)
            .padding(.bottom, 24)
        }
        .background(DS.ColorToken.appBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DS.ColorToken.purple)
                .frame(width: 18)

            Text(label)
                .font(DS.Typography.caption)
                .foregroundColor(DS.ColorToken.textSecondary)
                .frame(width: 64, alignment: .leading)

            Text(value)
                .font(DS.Typography.body)
                .foregroundColor(DS.ColorToken.textPrimary)

            Spacer(minLength: 0)
        }
    }
}

