//
//  PlannerView.swift
//  TaskPlanner
//

import SwiftUI

struct PlannerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = PlannerViewModel()
    @State private var showCreateTask = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    header
                    calendarCard
                    tasksSection
                }
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.top, DS.Spacing.lg)
                .padding(.bottom, 110) // space for pill tab bar
            }
            .navigationBarHidden(true)
            .background(DS.ColorToken.appBackground.ignoresSafeArea())
        }
        .onAppear {
            viewModel.configure(context: viewContext)
        }
        .sheet(isPresented: $showCreateTask) {
            TaskEditorView(mode: .create)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Task Planner")
                    .font(DS.Typography.title)
                    .foregroundColor(DS.ColorToken.textPrimary)

                Text("Organize your day with ease")
                    .font(DS.Typography.subtitle)
                    .foregroundColor(DS.ColorToken.textSecondary)
            }

            Spacer(minLength: 12)

            Button {
                // TODO: notifications screen
            } label: {
                Image(systemName: "bell")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DS.ColorToken.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: DS.Shadow.soft, radius: 10, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Notifications")
        }
    }

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            monthHeader
            weekdayHeader
            monthGrid
        }
        .dsCard()
    }

    private var monthHeader: some View {
        HStack {
            Button {
                viewModel.goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DS.ColorToken.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(viewModel.displayedMonth.formattedMonthYear())
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(DS.ColorToken.textPrimary)

            Spacer()

            Button {
                viewModel.goToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DS.ColorToken.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var weekdayHeader: some View {
        let symbols = Calendar.current.shortWeekdaySymbols // Sun..Sat
        return HStack(spacing: 0) {
            ForEach(symbols, id: \.self) { sym in
                Text(sym)
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.ColorToken.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthGrid: some View {
        let calendar = Calendar.current
        let monthStart = calendar.startOfMonth(for: viewModel.displayedMonth)
        let days = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        let firstWeekday = calendar.component(.weekday, from: monthStart) // 1 = Sunday
        let leadingEmpty = max(0, firstWeekday - calendar.firstWeekday) // when firstWeekday = 1 and firstWeekdaySymbol starts Sun, leading = 0
        let totalCells = leadingEmpty + days

        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(0..<totalCells, id: \.self) { idx in
                if idx < leadingEmpty {
                    Color.clear
                        .frame(height: 44)
                } else {
                    let day = idx - leadingEmpty + 1
                    let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) ?? monthStart
                    DayCell(
                        dayNumber: day,
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: viewModel.selectedDay),
                        indicatorCount: viewModel.taskCountByDay[calendar.startOfDay(for: date)] ?? 0
                    ) {
                        viewModel.selectDay(date)
                    }
                }
            }
        }
        .padding(.top, 6)
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            HStack {
                Text("Tasks for \(viewModel.selectedDay.formattedDayTitle())")
                    .font(DS.Typography.sectionTitle)
                    .foregroundColor(DS.ColorToken.textPrimary)
                Spacer()
                HStack(spacing: 10) {
                    Text("\(viewModel.dayTasks.count) tasks")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(DS.ColorToken.purple)

                    Button {
                        showCreateTask = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(DS.GradientToken.brand)
                            .clipShape(Circle())
                            .shadow(color: DS.Shadow.soft, radius: 10, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Create Task")
                }
            }

            if viewModel.dayTasks.isEmpty {
                emptyCard
            } else {
                VStack(spacing: DS.Spacing.sm) {
                    ForEach(viewModel.dayTasks, id: \.objectID) { task in
                        NavigationLink {
                            TaskDetailsView(task: task)
                        } label: {
                            TaskCard(task: task)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var emptyCard: some View {
        HStack(spacing: 12) {
            Circle()
                .strokeBorder(DS.ColorToken.textSecondary.opacity(0.3), lineWidth: 2)
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 4) {
                Text("No tasks yet")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(DS.ColorToken.textPrimary)
                Text("Tap + later to create your first task.")
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.ColorToken.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(DS.Spacing.md)
        .background(Color.white)
        .cornerRadius(DS.Radius.md)
        .shadow(color: DS.Shadow.soft, radius: 12, x: 0, y: 8)
    }
}

private struct DayCell: View {
    let dayNumber: Int
    let date: Date
    let isSelected: Bool
    let indicatorCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text("\(dayNumber)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : DS.ColorToken.textPrimary)
                    .frame(width: 34, height: 34)
                    .background(
                        Group {
                            if isSelected {
                                DS.ColorToken.purple
                            } else {
                                Color.clear
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                indicators
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var indicators: some View {
        let shown = min(3, indicatorCount)
        return HStack(spacing: 3) {
            ForEach(0..<shown, id: \.self) { _ in
                Capsule(style: .continuous)
                    .fill(DS.ColorToken.purple.opacity(0.65))
                    .frame(width: 7, height: 3)
            }
            if shown == 0 {
                Color.clear.frame(width: 7, height: 3)
            }
        }
    }

    private var accessibilityLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return "\(formatter.string(from: date)), \(indicatorCount) tasks"
    }
}

private struct TaskCard: View {
    let task: TaskEntity

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(task.wIsDone ? DS.ColorToken.purple : Color.clear)
                .overlay(
                    Circle()
                        .strokeBorder(DS.ColorToken.textSecondary.opacity(0.25), lineWidth: 2)
                )
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 6) {
                Text(task.wTitle)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(DS.ColorToken.textPrimary)

                Text(!task.wDetails.isEmpty ? task.wDetails : task.wCategory)
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.ColorToken.textSecondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DS.ColorToken.textSecondary)
                    Text("\(task.wStartTime.formatted(date: .omitted, time: .shortened)) – \(task.wEndTime.formatted(date: .omitted, time: .shortened))")
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.ColorToken.textSecondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(DS.Spacing.md)
        .background(taskBackgroundColor(for: task.wColorTag))
        .cornerRadius(DS.Radius.md)
        .shadow(color: DS.Shadow.soft, radius: 12, x: 0, y: 8)
    }

    private func taskBackgroundColor(for colorTag: String) -> Color {
        switch colorTag.lowercased() {
        case "blue":
            return Color(red: 0.84, green: 0.92, blue: 1.00)
        case "purple":
            return Color(red: 0.90, green: 0.86, blue: 1.00)
        case "pink":
            return Color(red: 1.00, green: 0.88, blue: 0.94)
        case "red":
            return Color(red: 1.00, green: 0.88, blue: 0.88)
        case "yellow":
            return Color(red: 1.00, green: 0.96, blue: 0.84)
        case "green":
            return Color(red: 0.86, green: 0.97, blue: 0.90)
        default:
            return Color.white
        }
    }
}

#Preview {
    PlannerView()
}

