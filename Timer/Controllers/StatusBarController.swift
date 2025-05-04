//
//  StatusBarController.swift
//  Timer
//
//  Created by Bohdan Ptyts on 01.05.2025.
//

import SwiftUI
import AppKit
import Combine

class StatusBarController {
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem?
    private var popover: NSPopover
    var appState = AppState()
    private var settingsManager: SettingsWindowManager!
    private var timerUpdateSubscription: AnyCancellable?
    private var statusMenu: NSMenu?
    private var appearanceObserver: NSObjectProtocol?
    private var menuBarTextVisibilityObserver: NSObjectProtocol?
    
    init() {
        statusBar = NSStatusBar.system
        
        // Create status item
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        
        // Create popover first
        popover = NSPopover()
        popover.behavior = .transient
        
        // Then initialize appState
        appState.statusBarController = self
        
        // Create the content view with the initialized appState
        popover.contentViewController = NSHostingController(rootView: PopoverView().environmentObject(appState))
        
        // Initialize settings manager with appState
        settingsManager = SettingsWindowManager(appState: appState)
        
        // Set up appearance mode observer
        setupAppearanceModeObserver()
        
        // Set up menu bar text visibility observer
        setupMenuBarTextVisibilityObserver()
        
        // Configure button with the icon
        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "timer",
                accessibilityDescription: "Timer")
            button.imagePosition = .imageLeft  // Place image on the left
            button.target = self
            button.action = #selector(togglePopover)
            
            // Setup right-click menu
            setupContextMenu()
        }
        
        // Subscribe to timer updates
        setupTimerUpdates()
        
        // Update the menu bar with the initial timer value
        updateMenuBarTimer(timerValue: appState.currentTimerValue)
        
        // Apply initial appearance
        updatePopoverAppearance()
    }
    
    deinit {
        // Remove observers when this controller is deallocated
        if let observer = appearanceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        if let observer = menuBarTextVisibilityObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func setupContextMenu() {
        // Create the menu
        let menu = NSMenu()
        
        // Add Play/Pause button
        let playPauseItem = NSMenuItem(
            title: appState.timerState != .inactive ? "Pause" : "Play",
            action: #selector(toggleTimer),
            keyEquivalent: "p"
        )
        playPauseItem.target = self
        menu.addItem(playPauseItem)
        
        // Add Reset button
        let resetItem = NSMenuItem(
            title: "Reset",
            action: #selector(resetTimer),
            keyEquivalent: "r"
        )
        resetItem.target = self
        menu.addItem(resetItem)
        
        // Add separator
        menu.addItem(NSMenuItem.separator())
        
        // Add Settings button
        let settingsItem = NSMenuItem(
            title: "Settings",
            action: #selector(openSettingsFromMenu),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        // Add Version info item
        let versionInfo = getVersionInfo()
        let versionItem = NSMenuItem(
            title: "Version: \(versionInfo)",
            action: nil,
            keyEquivalent: ""
        )
        menu.addItem(versionItem)
        
        // Add separator
        menu.addItem(NSMenuItem.separator())
        
        // Add a "Quit" option
        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApplication),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        // Store the menu
        statusMenu = menu
        
        // Set up the right-click event handler
        if let button = statusItem?.button {
            // Override the mouse down event to detect right clicks
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            
            // Replace the existing action with a new one that handles both left and right clicks
            button.action = #selector(handleStatusItemClick)
        }
    }
    
    @objc func handleStatusItemClick(sender: NSStatusBarButton) {
        // Get the current event
        if let event = NSApp.currentEvent {
            if event.type == .rightMouseUp {
                // Show the context menu on right-click
                if let menu = statusMenu {
                    statusItem?.menu = menu
                    statusItem?.button?.performClick(nil)
                    statusItem?.menu = nil  // Reset after use
                }
            } else if event.type == .leftMouseUp {
                // Handle left-click as before
                togglePopover(sender: sender)
            }
        }
    }
    
    @objc func quitApplication() {
        NSApp.terminate(nil)
    }
    
    private func setupTimerUpdates() {
        // Create a subscription to timer updates
        timerUpdateSubscription = appState.timerUpdatePublisher.sink { [weak self] timerValue in
            self?.updateMenuBarTimer(timerValue: timerValue)
        }
    }
    
    private func updateMenuBarTimer(timerValue: TimeInterval) {
        // Ensure we have a button to update
        guard let button = statusItem?.button else { return }
        
        // Get the minutes and seconds
        let minutes = Int(timerValue) / 60
        let seconds = Int(timerValue) % 60
        
        // Format the time string
        let timeString = String(format: "%02d:%02d", minutes, seconds)
        
        // Update the menu bar
        // Show the time string only if the setting is enabled
        button.title = appState.showTimerTextInMenuBar ? timeString : ""
        
        // Use a monospaced font to prevent shifting
        let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize + 1, weight: .regular)
        button.font = font
        
        // Always keep the image on the left
        button.imagePosition = .imageLeft
        
        // Set icon color based on timer mode
        if appState.timerState != .inactive {
            if appState.timerState == .breakActive {
                // Green icon for break time
                let greenIcon = NSImage(
                    systemSymbolName: "timer",
                    accessibilityDescription: "Timer"
                )?.withSymbolConfiguration(
                    NSImage.SymbolConfiguration(paletteColors: [.systemGreen])
                )
                button.image = greenIcon
            } else {
                // Default icon for focus time
                button.image = NSImage(
                    systemSymbolName: "timer",
                    accessibilityDescription: "Timer"
                )
            }
        } else {
            // Gray icon when timer is not active
            let grayIcon = NSImage(
                systemSymbolName: "timer",
                accessibilityDescription: "Timer"
            )?.withSymbolConfiguration(
                NSImage.SymbolConfiguration(paletteColors: [.secondaryLabelColor])
            )
            button.image = grayIcon
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
            if let button = statusItem?.button {
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
    
    @objc func toggleTimer() {
        // We need to publish an event that the PopoverView can listen to
        // rather than just changing the flag directly
        
        // Toggle the timer state
        let newTimerState = appState.timerState == .inactive
        
        // Send a notification to start/stop the timer
        // We'll use NotificationCenter for this cross-component communication
        NotificationCenter.default.post(
            name: newTimerState ? .startTimer : .stopTimer,
            object: nil
        )
        
        // Update the menu item title for next time
        if let menu = statusMenu,
           let playPauseItem = menu.items.first {
            playPauseItem.title = newTimerState ? "Pause" : "Play"
        }
    }
    
    @objc func resetTimer() {
        // Stop the timer first if it's running
        if appState.timerState != .inactive {
            NotificationCenter.default.post(name: .stopTimer, object: nil)
        }
        
        // Send reset notification
        NotificationCenter.default.post(name: .resetTimer, object: nil)
        
        // Update the timer value to reset the display
        appState.timerUpdatePublisher.send(0)
    }
    
    @objc func openSettingsFromMenu() {
        openSettings()
    }
    
    // Helper method to get version and build information
    private func getVersionInfo() -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(appVersion) (\(buildNumber))"
    }
    
    private func setupAppearanceModeObserver() {
        // Listen for appearance mode changes
        appearanceObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AppearanceModeDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updatePopoverAppearance()
        }
    }
    
    private func updatePopoverAppearance() {
        DispatchQueue.main.async {
            switch self.appState.appearanceMode {
            case .light:
                self.popover.appearance = NSAppearance(named: .aqua)
            case .dark:
                self.popover.appearance = NSAppearance(named: .darkAqua)
            case .system:
                self.popover.appearance = nil // Use system default
            }
        }
    }
    
    // MARK: - Menu Bar Text Visibility Handling
    
    private func setupMenuBarTextVisibilityObserver() {
        // Listen for menu bar text visibility changes
        menuBarTextVisibilityObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("MenuBarTextVisibilityDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateMenuBarTimer(timerValue: self?.appState.currentTimerValue ?? 0)
        }
    }
}

extension Notification.Name {
    static let startTimer = Notification.Name("startTimer")
    static let stopTimer = Notification.Name("stopTimer")
    static let resetTimer = Notification.Name("resetTimer")
}
