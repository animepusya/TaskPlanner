//
//  StatisticsView.swift
//  TaskPlanner
//

import SwiftUI
import CoreData

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = StatisticsViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    header
                    monthSelectorCard
                    timeByCategoryCard
                    totalHoursCard
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
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environment(\.managedObjectContext, viewContext)
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: viewContext)) { _ in
            viewModel.refreshMonth()
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Statistics")
                .font(DS.Typography.title)
                .foregroundColor(DS.ColorToken.textPrimary)
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(DS.ColorToken.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: DS.Shadow.soft, radius: 10, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Profile")
        }
    }

    private var monthSelectorCard: some View {
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
        .dsCard()
    }

    private var timeByCategoryCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("Time by Category")
                .font(DS.Typography.sectionTitle)
                .foregroundColor(DS.ColorToken.textPrimary)

            HStack(alignment: .center, spacing: DS.Spacing.lg) {
                donut
                    .frame(width: 140, height: 140)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.categoryStats) { stat in
                        CategoryLegendRow(
                            name: stat.name,
                            percentText: percentString(viewModel.percent(for: stat)),
                            color: categoryColor(stat)
                        )
                    }
                    if viewModel.categoryStats.isEmpty {
                        Text("No data for this month yet.")
                            .font(DS.Typography.caption)
                            .foregroundColor(DS.ColorToken.textSecondary)
                    }
                }
            }
        }
        .dsCard()
    }

    private var donut: some View {
        let slices: [DonutChartSlice] = viewModel.categoryStats.map { stat in
            DonutChartSlice(
                id: stat.id,
                fraction: viewModel.percent(for: stat),
                color: categoryColor(stat)
            )
        }

        return ZStack {
            DonutChartView(slices: normalizedSlices(slices), lineWidth: 18)
            VStack(spacing: 2) {
                Text(viewModel.totalSeconds.formattedHoursMinutes())
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(DS.ColorToken.textPrimary)
                Text("Total")
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.ColorToken.textSecondary)
            }
        }
    }

    private func normalizedSlices(_ slices: [DonutChartSlice]) -> [DonutChartSlice] {
        // Avoid tiny floating errors pushing trim > 1.0
        let sum = slices.reduce(0) { $0 + $1.fraction }
        guard sum > 0 else { return [] }
        return slices.map { DonutChartSlice(id: $0.id, fraction: $0.fraction / sum, color: $0.color) }
    }

    private var totalHoursCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            HStack {
                Text("Total Hours")
                    .font(DS.Typography.sectionTitle)
                    .foregroundColor(DS.ColorToken.textPrimary)
                Spacer()
                Text(viewModel.totalSeconds.formattedHoursMinutes())
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(DS.ColorToken.purple)
            }

            VStack(spacing: 10) {
                ForEach(viewModel.categoryStats) { stat in
                    HStack {
                        Circle()
                            .fill(categoryColor(stat))
                            .frame(width: 10, height: 10)
                        Text(stat.name)
                            .font(DS.Typography.body)
                            .foregroundColor(DS.ColorToken.textPrimary)
                        Spacer()
                        Text(stat.seconds.formattedHoursMinutes())
                            .font(DS.Typography.body)
                            .foregroundColor(DS.ColorToken.textSecondary)
                    }
                }
                if viewModel.categoryStats.isEmpty {
                    Text("Add some tasks to see monthly totals.")
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.ColorToken.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .dsCard()
    }

    private func categoryColor(_ stat: CategoryStat) -> Color {
        switch stat.name {
        case "Work":
            return DS.ColorToken.purple
        case "Study":
            return Color(red: 0.32, green: 0.62, blue: 0.98)
        case "Hobby":
            return Color(red: 0.98, green: 0.45, blue: 0.72)
        default:
            // fallback to colorTag if category unknown
            return colorFromTag(stat.colorTag)
        }
    }

    private func colorFromTag(_ tag: String) -> Color {
        switch tag.lowercased() {
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

    private func percentString(_ value: Double) -> String {
        let pct = Int((value * 100).rounded())
        return "\(pct)%"
    }
}

#Preview {
    StatisticsView()
}

private struct CategoryLegendRow: View {
    let name: String
    let percentText: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(name)
                .font(DS.Typography.body)
                .foregroundColor(DS.ColorToken.textPrimary)
            Spacer()
            Text(percentText)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(DS.ColorToken.textSecondary)
        }
    }
}

#Preview {
    StatisticsView()
}

