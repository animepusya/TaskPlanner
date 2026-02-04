//
//  StatisticsView.swift
//  TaskPlanner
//

import SwiftUI

struct StatisticsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    header
                    monthSelectorPlaceholder
                    donutPlaceholder
                    totalsPlaceholder
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
        HStack(alignment: .center) {
            Text("Statistics")
                .font(DS.Typography.title)
                .foregroundColor(DS.ColorToken.textPrimary)
            Spacer()
            Button {
                // TODO: settings/profile
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

    private var monthSelectorPlaceholder: some View {
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
        .dsCard()
    }

    private var donutPlaceholder: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("Time by Category")
                .font(DS.Typography.sectionTitle)
                .foregroundColor(DS.ColorToken.textPrimary)

            Text("Custom donut chart (no Swift Charts) will be implemented next.")
                .font(DS.Typography.caption)
                .foregroundColor(DS.ColorToken.textSecondary)
        }
        .dsCard()
    }

    private var totalsPlaceholder: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("Total Hours")
                .font(DS.Typography.sectionTitle)
                .foregroundColor(DS.ColorToken.textPrimary)
            Text("0h 0m")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(DS.ColorToken.purple)
        }
        .dsCard()
    }
}

#Preview {
    StatisticsView()
}

