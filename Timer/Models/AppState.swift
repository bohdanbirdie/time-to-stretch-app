//
//  AppState.swift
//  Timer
//
//  Created by Bohdan Ptyts on 01.05.2025.
//

import Foundation
import Combine
import SwiftUI

// Timer state enum to represent the different states of the timer
enum TimerState {
    case inactive
    case focusActive
    case breakActive
}

// App state class to provide access to StatusBarController from SwiftUI views
class AppState: ObservableObject {
    weak var statusBarController: StatusBarController?
    @Published var timerSettings: TimerSettings
    
    // Timer state tracking
    @Published var timerState: TimerState = .inactive
    @Published var currentTimerValue: TimeInterval = 0
    
    // Pending settings change that needs confirmation
    @Published var pendingSettingsChange: PendingSettingsChange?
    
    // Publisher for settings changes
    let settingsChangedPublisher = PassthroughSubject<TimerSettings, Never>()
    
    // Publisher for timer updates
    let timerUpdatePublisher = PassthroughSubject<TimeInterval, Never>()
    
    // UserDefaults keys
    private let timerSettingsKey = "timerSettings"
    
    init() {
        // Load settings from UserDefaults or use defaults
        if let savedSettingsData = UserDefaults.standard.data(forKey: timerSettingsKey),
           let decodedSettings = try? JSONDecoder().decode(TimerSettings.self, from: savedSettingsData) {
            self.timerSettings = decodedSettings
        } else {
            self.timerSettings = TimerSettings.defaultSettings
        }
    }
    
    func openSettings() {
        statusBarController?.openSettings()
    }
    
    // This is called when settings are changed in the UI
    func prepareSettingsUpdate(focusMinutes: Int, breakMinutes: Int, breakSeconds: Int) {
        // If timer is active, store as pending change that needs confirmation
        if timerState != .inactive {
            pendingSettingsChange = PendingSettingsChange(
                focusMinutes: focusMinutes,
                breakMinutes: breakMinutes,
                breakSeconds: breakSeconds
            )
        } else {
            // If timer is not active, apply immediately
            updateTimerSettings(
                focusMinutes: focusMinutes,
                breakMinutes: breakMinutes,
                breakSeconds: breakSeconds
            )
        }
    }
    
    // Confirm pending settings change
    func confirmPendingSettingsChange() {
        if let pending = pendingSettingsChange {
            updateTimerSettings(
                focusMinutes: pending.focusMinutes,
                breakMinutes: pending.breakMinutes,
                breakSeconds: pending.breakSeconds
            )
            pendingSettingsChange = nil
        }
    }
    
    // Cancel pending settings change
    func cancelPendingSettingsChange() {
        pendingSettingsChange = nil
    }
    
    // Actually update the settings
    func updateTimerSettings(focusMinutes: Int, breakMinutes: Int, breakSeconds: Int) {
        timerSettings = TimerSettings(focusMinutes: focusMinutes, breakMinutes: breakMinutes, breakSeconds: breakSeconds)
        saveSettings()
        
        // Notify subscribers that settings have changed
        settingsChangedPublisher.send(timerSettings)
    }
    
    private func saveSettings() {
        // Save settings to UserDefaults
        if let encodedData = try? JSONEncoder().encode(timerSettings) {
            UserDefaults.standard.set(encodedData, forKey: timerSettingsKey)
        }
    }
}
