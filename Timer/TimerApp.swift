//
//  TimerApp.swift
//  Timer
//
//  Created by Bohdan Ptyts on 01.05.2025.
//

import SwiftUI
import AppKit
import Combine

// Simple struct to hold timer settings
struct TimerSettings: Codable {
    var focusMinutes: Int
    var breakMinutes: Int
    var breakSeconds: Int
    
    // Default settings
    static let defaultSettings = TimerSettings(
        focusMinutes: 60, 
        breakMinutes: 5,
        breakSeconds: 0
    )
}

// Pending settings change that needs confirmation
struct PendingSettingsChange {
    var focusMinutes: Int
    var breakMinutes: Int
    var breakSeconds: Int
}

// App state class to provide access to StatusBarController from SwiftUI views
class AppState: ObservableObject {
    weak var statusBarController: StatusBarController?
    @Published var timerSettings: TimerSettings
    
    // Timer state tracking
    @Published var isTimerActive = false
    
    // Pending settings change that needs confirmation
    @Published var pendingSettingsChange: PendingSettingsChange?
    
    // Publisher for settings changes
    let settingsChangedPublisher = PassthroughSubject<TimerSettings, Never>()
    
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
        if isTimerActive {
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

// Window manager for Settings window
class SettingsWindowManager {
    private var window: NSWindow?
    private var appState: AppState
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    func showSettings() {
        // If window already exists, just bring it to front
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            window.level = .floating
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create the window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Timer Settings"
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        
        // Create a binding that closes the window when set to false
        let isPresented = Binding<Bool>(
            get: { true },
            set: { if !$0 { window.close() } }
        )
        
        // Set the content view to our settings view
        window.contentView = NSHostingView(rootView: SettingsView(isPresented: isPresented)
            .environmentObject(appState))
        
        // Add a handler for window close
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: nil
        ) { [weak self] _ in
            self?.window = nil
        }
        
        // Show the window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Store the window
        self.window = window
    }
}

class StatusBarController {
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    var appState = AppState()
    private var settingsManager: SettingsWindowManager!
    
    init() {
        statusBar = NSStatusBar.system
        statusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        
        // Create popover first
        popover = NSPopover()
        popover.behavior = .transient
        
        // Then initialize appState
        appState.statusBarController = self
        
        // Create the content view with the initialized appState
        popover.contentViewController = NSHostingController(rootView: PopoverView().environmentObject(appState))
        
        // Initialize settings manager with appState
        settingsManager = SettingsWindowManager(appState: appState)
        
        // Configure button
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "timer",
                accessibilityDescription: "Timer")
            button.target = self
            button.action = #selector(togglePopover)
        }
    }
    
    func openSettings() {
        // Open settings without closing the popover
        settingsManager.showSettings()
    }
    
    @objc func togglePopover(sender: AnyObject) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            if let button = statusItem.button {
                // Use direct presentation without animation context
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                
                // Make the popover's view the first responder to ensure it has focus
                if let contentViewController = popover.contentViewController,
                   let window = contentViewController.view.window {
                    window.makeFirstResponder(contentViewController.view)
                    window.makeKey()
                }
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Immediately create the status bar controller when the app launches
        statusBarController = StatusBarController()
    }
}

@main
struct TimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
