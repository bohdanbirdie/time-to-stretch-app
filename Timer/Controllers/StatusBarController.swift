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
    private var timerSettingsObserver: NSObjectProtocol?
    private var shortcutSettingsObserver: NSObjectProtocol?
    
    init() {
        statusBar = NSStatusBar.system
        
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        
        popover = NSPopover()
        popover.behavior = .transient
        
        appState.statusBarController = self
        
        popover.contentViewController = NSHostingController(rootView: PopoverView().environmentObject(appState))
        
        settingsManager = SettingsWindowManager(appState: appState)
        
        setupAppearanceModeObserver()
        
        setupMenuBarTextVisibilityObserver()
        
        setupTimerSettingsObserver()
        
        setupShortcutSettingsObserver()
        
        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "timer",
                accessibilityDescription: "Timer")
            button.imagePosition = .imageLeft  // Place image on the left
            button.target = self
            button.action = #selector(togglePopover)
            
            setupContextMenu()
        }
        
        setupTimerUpdates()
        
        updateMenuBarTimer(timerValue: appState.currentTimerValue)
        
        updatePopoverAppearance()
    }
    
    deinit {
        if let observer = appearanceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        if let observer = menuBarTextVisibilityObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        if let observer = timerSettingsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        if let observer = shortcutSettingsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func setupContextMenu() {
        let menu = NSMenu()
        
        let playPauseItem = NSMenuItem(
            title: appState.timerState != .inactive ? "Pause" : "Play",
            action: #selector(toggleTimer),
            keyEquivalent: ""
        )
        playPauseItem.target = self
        
        if appState.shortcutSettings.playPauseShortcut.isEnabled {
            let shortcut = appState.shortcutSettings.playPauseShortcut
            playPauseItem.keyEquivalent = shortcut.character.lowercased()
            
            let modifiers = NSEvent.ModifierFlags(rawValue: shortcut.modifiers)
            var keyEquivalentModifierMask: NSEvent.ModifierFlags = []
            
            if modifiers.contains(.command) { keyEquivalentModifierMask.insert(.command) }
            if modifiers.contains(.option) { keyEquivalentModifierMask.insert(.option) }
            if modifiers.contains(.control) { keyEquivalentModifierMask.insert(.control) }
            if modifiers.contains(.shift) { keyEquivalentModifierMask.insert(.shift) }
            
            playPauseItem.keyEquivalentModifierMask = keyEquivalentModifierMask
        }
        
        menu.addItem(playPauseItem)
        
        let resetItem = NSMenuItem(
            title: "Reset",
            action: #selector(resetTimer),
            keyEquivalent: ""
        )
        resetItem.target = self
        
        if appState.shortcutSettings.resetTimerShortcut.isEnabled {
            let shortcut = appState.shortcutSettings.resetTimerShortcut
            resetItem.keyEquivalent = shortcut.character.lowercased()
            
            let modifiers = NSEvent.ModifierFlags(rawValue: shortcut.modifiers)
            var keyEquivalentModifierMask: NSEvent.ModifierFlags = []
            
            if modifiers.contains(.command) { keyEquivalentModifierMask.insert(.command) }
            if modifiers.contains(.option) { keyEquivalentModifierMask.insert(.option) }
            if modifiers.contains(.control) { keyEquivalentModifierMask.insert(.control) }
            if modifiers.contains(.shift) { keyEquivalentModifierMask.insert(.shift) }
            
            resetItem.keyEquivalentModifierMask = keyEquivalentModifierMask
        }
        
        menu.addItem(resetItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let settingsItem = NSMenuItem(
            title: "Settings",
            action: #selector(openSettingsFromMenu),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        let versionInfo = getVersionInfo()
        let versionItem = NSMenuItem(
            title: "Version: \(versionInfo)",
            action: nil,
            keyEquivalent: ""
        )
        menu.addItem(versionItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApplication),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusMenu = menu
        
        if let button = statusItem?.button {
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            
            button.action = #selector(handleStatusItemClick)
        }
    }
    
    @objc func handleStatusItemClick(sender: NSStatusBarButton) {
        if let event = NSApp.currentEvent {
            if event.type == .rightMouseUp {
                if let menu = statusMenu {
                    statusItem?.menu = menu
                    statusItem?.button?.performClick(nil)
                    statusItem?.menu = nil  
                }
            } else if event.type == .leftMouseUp {
                togglePopover(sender: sender)
            }
        }
    }
    
    @objc func quitApplication() {
        NSApp.terminate(nil)
    }
    
    private func setupTimerUpdates() {
        timerUpdateSubscription = appState.timerUpdatePublisher.sink { [weak self] timerValue in
            self?.updateMenuBarTimer(timerValue: timerValue)
        }
    }
    
    private func updateMenuBarTimer(timerValue: TimeInterval) {
        guard let button = statusItem?.button else { return }
        
        let minutes = Int(timerValue) / 60
        let seconds = Int(timerValue) % 60
        
        let timeString = String(format: "%02d:%02d", minutes, seconds)
        
        button.title = appState.showTimerTextInMenuBar ? timeString : ""
        
        let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize + 1, weight: .regular)
        button.font = font
        
        button.imagePosition = .imageLeft
        
        if appState.timerState != .inactive {
            if appState.timerState == .breakActive {
                let greenIcon = NSImage(
                    systemSymbolName: "timer",
                    accessibilityDescription: "Timer"
                )?.withSymbolConfiguration(
                    NSImage.SymbolConfiguration(paletteColors: [.systemGreen])
                )
                button.image = greenIcon
            } else {
                button.image = NSImage(
                    systemSymbolName: "timer",
                    accessibilityDescription: "Timer"
                )
            }
        } else {
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
        settingsManager.showSettings()
    }
    
    @objc func togglePopover(sender: AnyObject) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            if let button = statusItem?.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                
                if let contentViewController = popover.contentViewController,
                   let window = contentViewController.view.window {
                    window.makeFirstResponder(contentViewController.view)
                    window.makeKey()
                }
            }
        }
    }
    
    @objc func toggleTimer() {
        let newTimerState = appState.timerState == .inactive
        
        NotificationCenter.default.post(
            name: newTimerState ? .startTimer : .stopTimer,
            object: nil
        )
        
        if let menu = statusMenu,
           let playPauseItem = menu.items.first {
            playPauseItem.title = newTimerState ? "Pause" : "Play"
        }
    }
    
    @objc func resetTimer() {
        if appState.timerState != .inactive {
            NotificationCenter.default.post(name: .stopTimer, object: nil)
        }
        
        NotificationCenter.default.post(name: .resetTimer, object: nil)
        
        appState.timerUpdatePublisher.send(0)
    }
    
    @objc func openSettingsFromMenu() {
        openSettings()
    }
    
    private func getVersionInfo() -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(appVersion) (\(buildNumber))"
    }
    
    private func setupAppearanceModeObserver() {
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
                self.popover.appearance = nil 
            }
        }
    }
    
    private func setupMenuBarTextVisibilityObserver() {
        menuBarTextVisibilityObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("MenuBarTextVisibilityDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateMenuBarTimer(timerValue: self?.appState.currentTimerValue ?? 0)
        }
    }
    
    private func setupTimerSettingsObserver() {
        timerSettingsObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("TimerSettingsDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateMenuBarTimer(timerValue: self?.appState.currentTimerValue ?? 0)
        }
    }
    
    private func setupShortcutSettingsObserver() {
        shortcutSettingsObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ShortcutSettingsDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.setupContextMenu()
        }
    }
}

extension Notification.Name {
    static let startTimer = Notification.Name("startTimer")
    static let stopTimer = Notification.Name("stopTimer")
    static let resetTimer = Notification.Name("resetTimer")
}
