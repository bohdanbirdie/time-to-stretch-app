//
//  AppState.swift
//  Timer
//
//  Created by Bohdan Ptyts on 01.05.2025.
//

import Foundation
import Combine
import SwiftUI
import ServiceManagement

// Timer state enum to represent the different states of the timer
enum TimerState {
    case inactive
    case focusActive
    case breakActive
}

// Appearance mode enum - simplified to match SwiftUI's ColorScheme
enum AppearanceMode: String, CaseIterable, Identifiable, Codable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { self.rawValue }
    
    // Convert to SwiftUI's ColorScheme
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil // nil means follow system
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

// App state class to provide access to StatusBarController from SwiftUI views
class AppState: ObservableObject {
    weak var statusBarController: StatusBarController?
    @Published var timerSettings: TimerSettings
    
    // Timer manager
    lazy var timerManager: TimerManager = {
        return TimerManager(appState: self)
    }()
    
    // Timer state tracking
    @Published var timerState: TimerState = .inactive
    @Published var currentTimerValue: TimeInterval = 0
    
    // Timer durations and remaining times
    @Published var focusRemainingTime: TimeInterval = 0
    @Published var breakRemainingTime: TimeInterval = 0
    @Published var focusDuration: TimeInterval = 0
    @Published var breakDuration: TimeInterval = 0
    
    // Timer instance (needs to be optional since it's a class)
    @Published var timer: Timer? = nil
    
    // App appearance settings - simplified
    @Published var appearanceMode: AppearanceMode = .system {
        didSet {
            saveAppearanceMode()
            // Post notification for appearance mode change
            NotificationCenter.default.post(name: NSNotification.Name("AppearanceModeDidChange"), object: nil)
        }
    }
    
    // UI Settings
    @Published var showTimerTextInMenuBar: Bool = true {
        didSet {
            saveShowTimerTextInMenuBar()
            // Post notification for menu bar visibility change
            NotificationCenter.default.post(name: NSNotification.Name("MenuBarTextVisibilityDidChange"), object: nil)
        }
    }
    
    // Auto-cycle timer setting
    var autoCycleTimer: Bool {
        get {
            return timerSettings.autoCycleTimer
        }
        set {
            timerSettings.autoCycleTimer = newValue
            saveSettings()
            objectWillChange.send()
        }
    }
    
    // Launch at startup setting
    @Published var launchAtStartup: Bool = false {
        didSet {
            updateLoginItemStatus()
        }
    }
    
    // Pending settings change that needs confirmation
    @Published var pendingSettingsChange: PendingSettingsChange?
    
    // Publisher for settings changes
    let settingsChangedPublisher = PassthroughSubject<TimerSettings, Never>()
    
    // Publisher for timer updates
    let timerUpdatePublisher = PassthroughSubject<TimeInterval, Never>()
    
    // UserDefaults keys
    private let timerSettingsKey = "timerSettings"
    private let appearanceModeKey = "appearanceMode"
    private let showTimerTextInMenuBarKey = "showTimerTextInMenuBar"
    private let launchAtStartupKey = "launchAtStartup"
    
    init() {
        // Load settings from UserDefaults or use defaults
        if let savedSettingsData = UserDefaults.standard.data(forKey: timerSettingsKey),
           let decodedSettings = try? JSONDecoder().decode(TimerSettings.self, from: savedSettingsData) {
            self.timerSettings = decodedSettings
        } else {
            self.timerSettings = TimerSettings.defaultSettings
        }
        
        // Initialize timer durations from settings
        updateTimerDurations()
        
        // Send initial timer value update
        timerUpdatePublisher.send(focusRemainingTime)
        
        // Load appearance mode
        loadAppearanceMode()
        
        // Load show timer text in menu bar setting
        loadShowTimerTextInMenuBar()
        
        // Load launch at startup setting
        loadLaunchAtStartup()
    }
    
    // Initialize timer durations based on settings
    private func updateTimerDurations() {
        focusDuration = TimeInterval(timerSettings.focusMinutes * 60)
        breakDuration = TimeInterval(timerSettings.breakMinutes * 60 + timerSettings.breakSeconds)
        
        // Reset remaining times to full duration
        resetTimerValues()
        
        // Update the current timer value
        currentTimerValue = focusRemainingTime
    }
    
    // Reset timer values to full duration
    func resetTimerValues() {
        focusRemainingTime = focusDuration
        breakRemainingTime = breakDuration
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
                breakSeconds: breakSeconds,
                autoCycleTimer: timerSettings.autoCycleTimer
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
            // Update autoCycleTimer separately since it's not part of updateTimerSettings
            timerSettings.autoCycleTimer = pending.autoCycleTimer
            saveSettings()
            pendingSettingsChange = nil
        }
    }
    
    // Cancel pending settings change
    func cancelPendingSettingsChange() {
        pendingSettingsChange = nil
    }
    
    // Actually update the settings
    func updateTimerSettings(focusMinutes: Int, breakMinutes: Int, breakSeconds: Int) {
        timerSettings = TimerSettings(
            focusMinutes: focusMinutes, 
            breakMinutes: breakMinutes, 
            breakSeconds: breakSeconds,
            autoCycleTimer: timerSettings.autoCycleTimer
        )
        saveSettings()
        
        // Update timer durations based on new settings
        updateTimerDurations()
        
        // Notify subscribers that settings have changed
        settingsChangedPublisher.send(timerSettings)
    }
    
    private func saveSettings() {
        // Save settings to UserDefaults
        if let encodedData = try? JSONEncoder().encode(timerSettings) {
            UserDefaults.standard.set(encodedData, forKey: timerSettingsKey)
            
            // Post notification that settings have changed
            NotificationCenter.default.post(name: NSNotification.Name("TimerSettingsDidChange"), object: nil)
        }
    }
    
    // Load appearance mode from UserDefaults
    private func loadAppearanceMode() {
        if let savedModeString = UserDefaults.standard.string(forKey: appearanceModeKey),
           let savedMode = AppearanceMode(rawValue: savedModeString) {
            self.appearanceMode = savedMode
        }
    }
    
    // Save appearance mode to UserDefaults
    func saveAppearanceMode() {
        UserDefaults.standard.set(appearanceMode.rawValue, forKey: appearanceModeKey)
    }
    
    // Load show timer text in menu bar setting from UserDefaults
    private func loadShowTimerTextInMenuBar() {
        // Default is true if not found
        self.showTimerTextInMenuBar = UserDefaults.standard.object(forKey: showTimerTextInMenuBarKey) as? Bool ?? true
    }
    
    // Save show timer text in menu bar setting to UserDefaults
    private func saveShowTimerTextInMenuBar() {
        UserDefaults.standard.set(showTimerTextInMenuBar, forKey: showTimerTextInMenuBarKey)
    }
    
    // Load launch at startup setting
    private func loadLaunchAtStartup() {
        self.launchAtStartup = UserDefaults.standard.bool(forKey: launchAtStartupKey)
        
        // Make sure the actual login item status matches our saved preference
        updateLoginItemStatus()
    }
    
    // Update login item status based on the launchAtStartup setting
    private func updateLoginItemStatus() {
        // Save the preference
        UserDefaults.standard.set(launchAtStartup, forKey: launchAtStartupKey)
        
        // Only supported on macOS 13 (Ventura) and later
        if #available(macOS 13.0, *) {
            do {
                if launchAtStartup {
                    // Register the app as a login item
                    try SMAppService.mainApp.register()
                } else {
                    // Unregister the app as a login item if it's registered
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                print("Failed to update login item status: \(error)")
            }
        } else {
            // For older macOS versions, just inform in debug console
            print("Launch at startup is only supported on macOS 13 and later")
        }
    }
}
