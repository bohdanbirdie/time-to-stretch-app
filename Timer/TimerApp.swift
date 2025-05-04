//
//  TimerApp.swift
//  Timer
//
//  Created by Bohdan Ptyts on 01.05.2025.
//

import SwiftUI
import AppKit
import UserNotifications

@main
struct TimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        Settings {
            EmptyView()
                .frame(width: 0, height: 0)
                .preferredColorScheme(appState.appearanceMode.colorScheme)
                .onChange(of: appState.appearanceMode) { _ in
                    appState.saveAppearanceMode()
                }
        }
        .environmentObject(appState)
    }
}
