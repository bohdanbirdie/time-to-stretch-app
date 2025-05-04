//
//  TimerPresets.swift
//  Timer
//
//  Created by Bohdan Ptyts on 04.05.2025.
//

import Foundation

// Structure to represent a timer preset
struct TimerPreset {
    let name: String
    let iconName: String
    let focusHours: Int
    let focusMinutes: Int
    let breakMinutes: Int
    let breakSeconds: Int
    
    // Computed property to get total focus minutes
    var totalFocusMinutes: Int {
        return (focusHours * 60) + focusMinutes
    }
}

// Class to provide timer presets
struct TimerPresets {
    // Pomodoro preset (25min focus, 5min break)
    static let pomodoro = TimerPreset(
        name: "Pomodoro",
        iconName: "timer",
        focusHours: 0,
        focusMinutes: 25,
        breakMinutes: 5,
        breakSeconds: 0
    )
    
    // Short work preset (50min focus, 10min break)
    static let shortWork = TimerPreset(
        name: "Short Work",
        iconName: "briefcase",
        focusHours: 0,
        focusMinutes: 50,
        breakMinutes: 10,
        breakSeconds: 0
    )
    
    // Long work preset (90min focus, 15min break)
    static let longWork = TimerPreset(
        name: "Long Work",
        iconName: "deskclock",
        focusHours: 1,
        focusMinutes: 30,
        breakMinutes: 15,
        breakSeconds: 0
    )
    
    // Array of all presets for easy iteration
    static let all: [TimerPreset] = [
        pomodoro,
        shortWork,
        longWork
    ]
}
