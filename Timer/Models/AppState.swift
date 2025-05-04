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

enum TimerState {
    case inactive
    case focusActive
    case breakActive
}

enum AppearanceMode: String, CaseIterable, Identifiable, Codable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { self.rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

class AppState: ObservableObject {
    weak var statusBarController: StatusBarController?
    @Published var timerSettings: TimerSettings
    @Published var shortcutSettings: ShortcutSettings {
        didSet {
            saveShortcutSettings()
            NotificationCenter.default.post(name: Notification.Name("ShortcutSettingsDidChange"), object: nil)
        }
    }
    
    lazy var timerManager: TimerManager = {
        return TimerManager(appState: self)
    }()
    
    @Published var timerState: TimerState = .inactive
    @Published var currentTimerValue: TimeInterval = 0
    
    @Published var focusRemainingTime: TimeInterval = 0
    @Published var breakRemainingTime: TimeInterval = 0
    @Published var focusDuration: TimeInterval = 0
    @Published var breakDuration: TimeInterval = 0
    
    @Published var timer: Timer? = nil
    
    @Published var appearanceMode: AppearanceMode = .system {
        didSet {
            saveAppearanceMode()
            NotificationCenter.default.post(name: Notification.Name("AppearanceModeDidChange"), object: nil)
        }
    }
    
    @Published var showTimerTextInMenuBar: Bool = true {
        didSet {
            saveShowTimerTextInMenuBar()
            NotificationCenter.default.post(name: Notification.Name("MenuBarTextVisibilityDidChange"), object: nil)
        }
    }
    
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
    
    @Published var launchAtStartup: Bool = false {
        didSet {
            updateLoginItemStatus()
        }
    }
    
    @Published var pendingSettingsChange: PendingSettingsChange?
    
    let settingsChangedPublisher = PassthroughSubject<TimerSettings, Never>()
    
    let timerUpdatePublisher = PassthroughSubject<TimeInterval, Never>()
    
    private let timerSettingsKey = "timerSettings"
    private let appearanceModeKey = "appearanceMode"
    private let showTimerTextInMenuBarKey = "showTimerTextInMenuBar"
    private let launchAtStartupKey = "launchAtStartup"
    private let shortcutSettingsKey = "shortcutSettings"
    
    init() {
        self.timerSettings = TimerSettings.defaultSettings
        self.shortcutSettings = ShortcutSettings.defaultSettings
        
        if let savedSettingsData = UserDefaults.standard.data(forKey: timerSettingsKey),
           let decodedSettings = try? JSONDecoder().decode(TimerSettings.self, from: savedSettingsData) {
            self.timerSettings = decodedSettings
        }
        
        if let savedShortcutData = UserDefaults.standard.data(forKey: shortcutSettingsKey),
           let decodedShortcuts = try? JSONDecoder().decode(ShortcutSettings.self, from: savedShortcutData) {
            self.shortcutSettings = decodedShortcuts
        }
        
        updateTimerDurations()
        
        timerUpdatePublisher.send(focusRemainingTime)
        
        loadAppearanceMode()
        
        loadShowTimerTextInMenuBar()
        
        loadLaunchAtStartup()
    }
    
    private func updateTimerDurations() {
        focusDuration = TimeInterval(timerSettings.focusMinutes * 60)
        breakDuration = TimeInterval(timerSettings.breakMinutes * 60 + timerSettings.breakSeconds)
        
        resetTimerValues()
        
        currentTimerValue = focusRemainingTime
        
        timerUpdatePublisher.send(currentTimerValue)
    }
    
    func resetTimerValues() {
        focusRemainingTime = focusDuration
        breakRemainingTime = breakDuration
    }
    
    func openSettings() {
        statusBarController?.openSettings()
    }
    
    func prepareSettingsUpdate(focusMinutes: Int, breakMinutes: Int, breakSeconds: Int) {
        let isTimerModified = focusRemainingTime != focusDuration || breakRemainingTime != breakDuration
        
        if isTimerModified {
            pendingSettingsChange = PendingSettingsChange(
                focusMinutes: focusMinutes,
                breakMinutes: breakMinutes,
                breakSeconds: breakSeconds,
                autoCycleTimer: timerSettings.autoCycleTimer
            )
        } else {
            updateTimerSettings(
                focusMinutes: focusMinutes,
                breakMinutes: breakMinutes,
                breakSeconds: breakSeconds
            )
        }
    }
    
    func confirmPendingSettingsChange() {
        if let pending = pendingSettingsChange {
            updateTimerSettings(
                focusMinutes: pending.focusMinutes,
                breakMinutes: pending.breakMinutes,
                breakSeconds: pending.breakSeconds
            )
            timerSettings.autoCycleTimer = pending.autoCycleTimer
            saveSettings()
            pendingSettingsChange = nil
        }
    }
    
    func cancelPendingSettingsChange() {
        pendingSettingsChange = nil
    }
    
    func updateTimerSettings(focusMinutes: Int, breakMinutes: Int, breakSeconds: Int) {
        if timer != nil {
            timer?.invalidate()
            timer = nil
            timerState = .inactive
            
            NotificationCenter.default.post(name: Notification.Name("stopTimer"), object: nil)
        }
        
        timerSettings = TimerSettings(
            focusMinutes: focusMinutes, 
            breakMinutes: breakMinutes, 
            breakSeconds: breakSeconds,
            autoCycleTimer: timerSettings.autoCycleTimer
        )
        saveSettings()
        
        updateTimerDurations()
        
        settingsChangedPublisher.send(timerSettings)
    }
    
    private func saveSettings() {
        if let encodedData = try? JSONEncoder().encode(timerSettings) {
            UserDefaults.standard.set(encodedData, forKey: timerSettingsKey)
            
            NotificationCenter.default.post(name: Notification.Name("TimerSettingsDidChange"), object: nil)
        }
    }
    
    private func loadAppearanceMode() {
        if let savedModeString = UserDefaults.standard.string(forKey: appearanceModeKey),
           let savedMode = AppearanceMode(rawValue: savedModeString) {
            self.appearanceMode = savedMode
        }
    }
    
    func saveAppearanceMode() {
        UserDefaults.standard.set(appearanceMode.rawValue, forKey: appearanceModeKey)
    }
    
    private func loadShowTimerTextInMenuBar() {
        self.showTimerTextInMenuBar = UserDefaults.standard.object(forKey: showTimerTextInMenuBarKey) as? Bool ?? true
    }
    
    private func saveShowTimerTextInMenuBar() {
        UserDefaults.standard.set(showTimerTextInMenuBar, forKey: showTimerTextInMenuBarKey)
    }
    
    private func loadLaunchAtStartup() {
        self.launchAtStartup = UserDefaults.standard.bool(forKey: launchAtStartupKey)
        
        updateLoginItemStatus()
    }
    
    private func updateLoginItemStatus() {
        UserDefaults.standard.set(launchAtStartup, forKey: launchAtStartupKey)
        
        if #available(macOS 13.0, *) {
            do {
                if launchAtStartup {
                    try SMAppService.mainApp.register()
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                print("Failed to update login item status: \(error)")
            }
        } else {
            print("Launch at startup is only supported on macOS 13 and later")
        }
    }
    
    private func saveShortcutSettings() {
        if let encodedData = try? JSONEncoder().encode(shortcutSettings) {
            UserDefaults.standard.set(encodedData, forKey: shortcutSettingsKey)
        }
    }
}
