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
    var globalShortcutManager: GlobalShortcutManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        requestNotificationPermissions()
        
        statusBarController = StatusBarController()
        
        setupAppearanceModeObserver()
        
        applyCurrentAppearanceMode()
        
        if let appState = statusBarController?.appState {
            globalShortcutManager = GlobalShortcutManager(appState: appState)
        }
    }
    
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
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               willPresent notification: UNNotification, 
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
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
                NSApp.appearance = nil
            }
        }
    }
}
