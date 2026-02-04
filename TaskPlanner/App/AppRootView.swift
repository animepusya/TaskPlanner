//
//  AppRootView.swift
//  TaskPlanner
//

import SwiftUI

struct AppRootView: View {
    @State private var didFinishSplash = false

    var body: some View {
        ZStack {
            if didFinishSplash {
                TabRootView()
                    .transition(.opacity)
            } else {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        didFinishSplash = true
                    }
                }
                .transition(.opacity)
            }
        }
        .background(DS.ColorToken.appBackground.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.35), value: didFinishSplash)
    }
}

#Preview {
    AppRootView()
}

