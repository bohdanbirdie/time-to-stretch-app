//
//  AppDelegate.swift
//  Timer
//
//  Created by Bohdan Ptyts on 01.05.2025.
//

import AppKit
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var statusBarController: StatusBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permissions
        requestNotificationPermissions()
        
        // Immediately create the status bar controller when the app launches
        statusBarController = StatusBarController()
        
        // Set up appearance mode observer
        setupAppearanceModeObserver()
        
        // Apply initial appearance mode
        applyCurrentAppearanceMode()
    }
    
    // Request permission to send notifications
    private func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permissions: \(error)")
            }
        }
    }
    
    // UNUserNotificationCenterDelegate method to handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               willPresent notification: UNNotification, 
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification even when the app is in the foreground
        completionHandler([.banner, .sound])
    }
    
    // MARK: - Appearance Mode Handling
    
    private func setupAppearanceModeObserver() {
        // Listen for appearance mode changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppearanceModeChange),
            name: NSNotification.Name("AppearanceModeDidChange"),
            object: nil
        )
    }
    
    @objc private func handleAppearanceModeChange() {
        applyCurrentAppearanceMode()
    }
    
    private func applyCurrentAppearanceMode() {
        let appState = (NSApplication.shared.delegate as? AppDelegate)?.statusBarController?.appState
        
        DispatchQueue.main.async {
            switch appState?.appearanceMode {
            case .light:
                NSApp.appearance = NSAppearance(named: .aqua)
            case .dark:
                NSApp.appearance = NSAppearance(named: .darkAqua)
            case .system, .none, nil:
                NSApp.appearance = nil // Use system default
            }
        }
    }
}
