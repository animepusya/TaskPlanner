//
//  PlannerView.swift
//  TaskPlanner
//

import SwiftUI

struct PlannerView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    header
                    calendarPlaceholder
                    tasksPlaceholder
                }
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.top, DS.Spacing.lg)
                .padding(.bottom, 110) // space for pill tab bar
            }
            .navigationBarHidden(true)
            .background(DS.ColorToken.appBackground.ignoresSafeArea())
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

    private var calendarPlaceholder: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            HStack {
                Button {} label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DS.ColorToken.textSecondary)
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                Text("February 2024")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(DS.ColorToken.textPrimary)

                Spacer()

                Button {} label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DS.ColorToken.textSecondary)
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            Text("Calendar UI will be implemented next (month grid, selection, dots).")
                .font(DS.Typography.caption)
                .foregroundColor(DS.ColorToken.textSecondary)
                .padding(.top, 2)
        }
        .dsCard()
    }

    private var tasksPlaceholder: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            HStack {
                Text("Tasks for Mon 12")
                    .font(DS.Typography.sectionTitle)
                    .foregroundColor(DS.ColorToken.textPrimary)
                Spacer()
                Text("0 tasks")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(DS.ColorToken.purple)
            }

            VStack(spacing: DS.Spacing.sm) {
                emptyCard
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

#Preview {
    PlannerView()
}

