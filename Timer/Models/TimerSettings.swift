//
//  TimerSettings.swift
//  Timer
//
//  Created by Bohdan Ptyts on 01.05.2025.
//

import Foundation

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
