//
//  TimerSettings.swift
//  Timer
//
//  Created by Bohdan Ptyts on 01.05.2025.
//

import Foundation

struct TimerSettings: Codable {
    var focusMinutes: Int
    var breakMinutes: Int
    var breakSeconds: Int
    var autoCycleTimer: Bool
    
    static let defaultSettings = TimerSettings(
        focusMinutes: 60, 
        breakMinutes: 5,
        breakSeconds: 0,
        autoCycleTimer: false
    )
}

struct PendingSettingsChange {
    var focusMinutes: Int
    var breakMinutes: Int
    var breakSeconds: Int
    var autoCycleTimer: Bool
}
