//
//  SettingsWindowManager.swift
//  Timer
//
//  Created by Bohdan Ptyts on 01.05.2025.
//

import SwiftUI
import AppKit

class SettingsWindowManager {
    private var window: NSWindow?
    private var appState: AppState
    private var appearanceObserver: NSObjectProtocol?
    
    init(appState: AppState) {
        self.appState = appState
        
        setupAppearanceModeObserver()
    }
    
    deinit {
        if let observer = appearanceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func showSettings() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            window.level = .floating
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
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
        
        let isPresented = Binding<Bool>(
            get: { true },
            set: { if !$0 { window.close() } }
        )
        
        window.contentView = NSHostingView(rootView: SettingsView(isPresented: isPresented)
            .environmentObject(appState))
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: nil
        ) { [weak self] _ in
            self?.window = nil
        }
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        self.window = window
        
        updateWindowAppearance()
    }
    
    private func setupAppearanceModeObserver() {
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
                window.appearance = nil 
            }
        }
    }
}
