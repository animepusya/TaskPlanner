//
//  TaskDetailsView.swift
//  TaskPlanner
//

import CoreData
import SwiftUI

struct TaskDetailsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var task: TaskEntity

    @State private var showEdit = false
    @State private var showDeleteAlert = false

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

                actionButtons
            }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.top, DS.Spacing.lg)
            .padding(.bottom, 24)
        }
        .background(DS.ColorToken.appBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showEdit = true
                } label: {
                    Text("Edit")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(DS.ColorToken.purple)
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            TaskEditorView(mode: .edit(task))
                .environment(\.managedObjectContext, viewContext)
        }
        .alert("Delete Task", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteTask()
            }
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
    }

    private var actionButtons: some View {
        HStack(spacing: DS.Spacing.md) {
            Button {
                toggleDone()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: task.wIsDone ? "arrow.uturn.backward.circle" : "checkmark.circle.fill")
                    Text(task.wIsDone ? "Mark as Undone" : "Mark as Done")
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(DS.GradientToken.brand)
                .cornerRadius(DS.Radius.pill)
            }
            .buttonStyle(.plain)

            Button {
                showDeleteAlert = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("Delete")
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.red)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color.red.opacity(0.08))
                .cornerRadius(DS.Radius.pill)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
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

    private func toggleDone() {
        viewContext.performAndWait {
            task.isDone.toggle()
        }
        do {
            try viewContext.save()
        } catch {
            assertionFailure("Failed to toggle done: \(error)")
        }
    }

    private func deleteTask() {
        viewContext.performAndWait {
            viewContext.delete(task)
        }
        do {
            try viewContext.save()
            dismiss()
        } catch {
            assertionFailure("Failed to delete task: \(error)")
        }
    }
}

