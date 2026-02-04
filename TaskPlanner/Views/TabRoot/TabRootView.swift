//
//  TabRootView.swift
//  TaskPlanner
//

import SwiftUI

enum RootTab: Hashable {
    case planner
    case statistics
}

struct TabRootView: View {
    @State private var selectedTab: RootTab = .planner

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .planner:
                    PlannerView()
                case .statistics:
                    StatisticsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            PillTabBar(
                selectedTab: $selectedTab,
                leftTitle: "February",
                leftSystemImage: "calendar",
                rightTitle: "Statistics",
                rightSystemImage: "chart.bar.xaxis"
            )
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.bottom, 10)
        }
        .background(DS.ColorToken.appBackground.ignoresSafeArea())
    }
}

private struct PillTabBar: View {
    @Binding var selectedTab: RootTab

    let leftTitle: String
    let leftSystemImage: String
    let rightTitle: String
    let rightSystemImage: String

    var body: some View {
        HStack(spacing: 10) {
            tabButton(
                tab: .planner,
                title: leftTitle,
                systemImage: leftSystemImage
            )
            tabButton(
                tab: .statistics,
                title: rightTitle,
                systemImage: rightSystemImage
            )
        }
        .padding(8)
        .background(Color.white.opacity(0.92))
        .cornerRadius(DS.Radius.pill)
        .shadow(color: DS.Shadow.soft, radius: 18, x: 0, y: 10)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func tabButton(tab: RootTab, title: String, systemImage: String) -> some View {
        let isActive = selectedTab == tab
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundColor(isActive ? .white : DS.ColorToken.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isActive {
                        DS.GradientToken.brand
                    } else {
                        Color.clear
                    }
                }
            )
            .cornerRadius(DS.Radius.pill)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
}

#Preview {
    TabRootView()
}

