//
//  TaskEditorView.swift
//  TaskPlanner
//

import CoreData
import SwiftUI

struct TaskEditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: TaskEditorViewModel
    @State private var showRepeatSheet = false

    init(mode: TaskEditorMode) {
        _viewModel = StateObject(wrappedValue: TaskEditorViewModel(mode: mode))
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    nameAndCategory
                    dateTimeCard
                    colorPickerRow
                    repeatRow
                    notesCard
                }
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.top, DS.Spacing.lg)
                .padding(.bottom, 28)
            }
        }
        .background(DS.ColorToken.appBackground.ignoresSafeArea())
        .sheet(isPresented: $showRepeatSheet) {
            RepeatRulePickerSheet(
                selected: $viewModel.repeatRule,
                rules: viewModel.repeatRules
            )
        }
        .alert("Can’t Save", isPresented: Binding(get: { viewModel.showValidationError }, set: { _ in })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.validationMessage)
        }
        .onChange(of: viewModel.dayDate) { _ in
            viewModel.syncTimesToSelectedDay()
        }
        .onChange(of: viewModel.startTime) { _ in
            // Keep date component in sync if user scrolls the wheel across midnight.
            viewModel.startTime = viewModel.aligned(time: viewModel.startTime, toDay: viewModel.dayDate)
        }
        .onChange(of: viewModel.endTime) { _ in
            viewModel.endTime = viewModel.aligned(time: viewModel.endTime, toDay: viewModel.dayDate)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DS.ColorToken.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: DS.Shadow.soft, radius: 10, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Spacer()

            Text(viewModel.mode.title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(DS.ColorToken.textPrimary)

            Spacer()

            Button {
                save()
            } label: {
                Text("Save")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(DS.GradientToken.brand)
                    .cornerRadius(DS.Radius.pill)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Save Task")
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }

    private var nameAndCategory: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("Task Name")
                .font(DS.Typography.caption)
                .foregroundColor(DS.ColorToken.textSecondary)

            HStack(spacing: 10) {
                TextField("Enter task name", text: $viewModel.taskName)
                    .font(DS.Typography.body)
                    .textInputAutocapitalization(.sentences)
                    .disableAutocorrection(false)

                Menu {
                    ForEach(viewModel.categories, id: \.self) { c in
                        Button {
                            viewModel.category = c
                        } label: {
                            if viewModel.category == c {
                                Label(c, systemImage: "checkmark")
                            } else {
                                Text(c)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(viewModel.category)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(DS.ColorToken.purple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(DS.ColorToken.purple.opacity(0.10))
                    .cornerRadius(DS.Radius.pill)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        }
        .dsCard()
    }

    private var dateTimeCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("Date & Time")
                .font(DS.Typography.sectionTitle)
                .foregroundColor(DS.ColorToken.textPrimary)

            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DS.ColorToken.purple)
                    .frame(width: 18)

                DatePicker("Date", selection: $viewModel.dayDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()

                Spacer()
            }

            HStack(spacing: DS.Spacing.md) {
                timeField(title: "Start Time", systemImage: "clock", selection: $viewModel.startTime)
                timeField(title: "End Time", systemImage: "clock", selection: $viewModel.endTime)
            }
        }
        .dsCard()
    }

    private func timeField(title: String, systemImage: String, selection: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(DS.Typography.caption)
                .foregroundColor(DS.ColorToken.textSecondary)
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DS.ColorToken.textSecondary)
                DatePicker("", selection: selection, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.compact)
            }
            .padding(10)
            .background(Color.black.opacity(0.04))
            .cornerRadius(DS.Radius.sm)
        }
        .frame(maxWidth: .infinity)
    }

    private var colorPickerRow: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("Color")
                .font(DS.Typography.sectionTitle)
                .foregroundColor(DS.ColorToken.textPrimary)

            HStack(spacing: 12) {
                ForEach(viewModel.colorTags, id: \.self) { tag in
                    Button {
                        viewModel.colorTag = tag
                    } label: {
                        Circle()
                            .fill(color(for: tag))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: viewModel.colorTag == tag ? 3 : 0)
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(DS.ColorToken.textSecondary.opacity(0.25), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tag)
                }
                Spacer(minLength: 0)
            }
        }
        .dsCard()
    }

    private var repeatRow: some View {
        Button {
            showRepeatSheet = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Repeat")
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.ColorToken.textSecondary)
                    Text(viewModel.repeatRule.capitalized)
                        .font(DS.Typography.body)
                        .foregroundColor(DS.ColorToken.textPrimary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DS.ColorToken.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .dsCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("Notes")
                .font(DS.Typography.sectionTitle)
                .foregroundColor(DS.ColorToken.textPrimary)

            TextEditor(text: $viewModel.notes)
                .font(DS.Typography.body)
                .frame(minHeight: 120)
                .padding(10)
                .background(Color.black.opacity(0.04))
                .cornerRadius(DS.Radius.sm)
        }
        .dsCard()
    }

    private func color(for tag: String) -> Color {
        switch tag {
        case "blue":
            return Color(red: 0.32, green: 0.62, blue: 0.98)
        case "purple":
            return DS.ColorToken.purple
        case "pink":
            return Color(red: 0.98, green: 0.45, blue: 0.72)
        case "red":
            return Color(red: 0.98, green: 0.35, blue: 0.35)
        case "yellow":
            return Color(red: 0.98, green: 0.80, blue: 0.20)
        case "green":
            return Color(red: 0.20, green: 0.75, blue: 0.48)
        default:
            return DS.ColorToken.textSecondary
        }
    }

    private func save() {
        viewModel.syncTimesToSelectedDay()
        guard viewModel.validate() else { return }

        let mode = viewModel.mode
        let title = viewModel.taskName.trimmingCharacters(in: .whitespacesAndNewlines)
        let notes = viewModel.notes
        let category = viewModel.category
        let colorTag = viewModel.colorTag
        let repeatRule = viewModel.repeatRule
        let startTime = viewModel.startTime
        let endTime = viewModel.endTime
        let day = Calendar.current.startOfDay(for: viewModel.dayDate)

        viewContext.performAndWait {
            let task: TaskEntity
            switch mode {
            case .create:
                task = TaskEntity(context: viewContext)
                task.id = UUID()
                task.createdAt = Date()
                task.isDone = false
            case .edit(let existing):
                task = existing
            }

            let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

            task.title = title
            task.details = trimmedNotes.isEmpty ? nil : trimmedNotes
            task.category = category
            task.colorTag = colorTag
            task.repeatRule = repeatRule
            task.dayDate = day
            task.startTime = startTime
            task.endTime = endTime
        }

        do {
            try viewContext.save()
            dismiss()
        } catch {
            // Keep minimal: surface as validation error style alert.
            viewModel.validationMessage = "Failed to save task."
            viewModel.showValidationError = true
            assertionFailure("Save failed: \(error)")
        }
    }
}

private struct RepeatRulePickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selected: String
    let rules: [String]

    var body: some View {
        NavigationView {
            List {
                ForEach(rules, id: \.self) { rule in
                    Button {
                        selected = rule
                        dismiss()
                    } label: {
                        HStack {
                            Text(rule.capitalized)
                                .foregroundColor(.primary)
                            Spacer()
                            if selected == rule {
                                Image(systemName: "checkmark")
                                    .foregroundColor(DS.ColorToken.purple)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Repeat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    TaskEditorView(mode: .create)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

