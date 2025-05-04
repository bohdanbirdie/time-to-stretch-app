//
//  SettingsWindowManager.swift
//  Timer
//
//  Created by Bohdan Ptyts on 01.05.2025.
//

import SwiftUI
import AppKit

// Window manager for Settings window
class SettingsWindowManager {
    private var window: NSWindow?
    private var appState: AppState
    private var appearanceObserver: NSObjectProtocol?
    
    init(appState: AppState) {
        self.appState = appState
        
        // Set up appearance mode observer
        setupAppearanceModeObserver()
    }
    
    deinit {
        // Remove the appearance observer when this manager is deallocated
        if let observer = appearanceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
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
        
        // Apply current appearance mode
        updateWindowAppearance()
    }
    
    // MARK: - Appearance Mode Handling
    
    private func setupAppearanceModeObserver() {
        // Listen for appearance mode changes
        appearanceObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AppearanceModeDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateWindowAppearance()
        }
    }
    
    private func updateWindowAppearance() {
        guard let window = window else { return }
        
        DispatchQueue.main.async {
            switch self.appState.appearanceMode {
            case .light:
                window.appearance = NSAppearance(named: .aqua)
            case .dark:
                window.appearance = NSAppearance(named: .darkAqua)
            case .system:
                window.appearance = nil // Use system default
            }
        }
    }
}
