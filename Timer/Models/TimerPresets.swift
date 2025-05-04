//
//  TimerPresets.swift
//  Timer
//
//  Created by Bohdan Ptyts on 04.05.2025.
//

import Foundation

struct TimerPreset {
    let name: String
    let iconName: String
    let focusHours: Int
    let focusMinutes: Int
    let breakMinutes: Int
    let breakSeconds: Int
    
    var totalFocusMinutes: Int {
        return (focusHours * 60) + focusMinutes
    }
}

struct TimerPresets {
    static let pomodoro = TimerPreset(
        name: "Pomodoro",
        iconName: "timer",
        focusHours: 0,
        focusMinutes: 25,
        breakMinutes: 5,
        breakSeconds: 0
    )
    
    static let shortWork = TimerPreset(
        name: "Short Work",
        iconName: "briefcase",
        focusHours: 0,
        focusMinutes: 50,
        breakMinutes: 10,
        breakSeconds: 0
    )
    
    static let longWork = TimerPreset(
        name: "Long Work",
        iconName: "deskclock",
        focusHours: 1,
        focusMinutes: 30,
        breakMinutes: 15,
        breakSeconds: 0
    )
    
    static let all: [TimerPreset] = [pomodoro, shortWork, longWork]
}
