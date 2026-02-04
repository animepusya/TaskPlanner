//
//  SplashView.swift
//  TaskPlanner
//

import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void

    @State private var pulse = false
    @State private var didScheduleFinish = false

    var body: some View {
        ZStack {
            DS.GradientToken.splash
                .ignoresSafeArea()

            VStack(spacing: DS.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: 120, height: 120)

                    Group {
                        if #available(iOS 17.0, *) {
                            Image(systemName: "calendar.badge.checkmark")
                        } else {
                            Image(systemName: "calendar")
                        }
                    }
                    .font(.system(size: 46, weight: .semibold, design: .rounded))
                    .foregroundColor(DS.ColorToken.purpleDark.opacity(0.9))

                }
                .scaleEffect(pulse ? 1.06 : 0.94)
                .opacity(pulse ? 1.0 : 0.78)

                VStack(spacing: 6) {
                    Text("Task Planner")
                        .font(DS.Typography.title)
                        .foregroundColor(DS.ColorToken.textPrimary)

                    Text("Organize your day with ease")
                        .font(DS.Typography.subtitle)
                        .foregroundColor(DS.ColorToken.textSecondary)
                }
            }
            .padding(.horizontal, DS.Spacing.xl)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
            guard !didScheduleFinish else { return }
            didScheduleFinish = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                onFinished()
            }
        }
    }
}

#Preview {
    SplashView(onFinished: {})
}

