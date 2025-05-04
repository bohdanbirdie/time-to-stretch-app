//
//  ShortcutSettings.swift
//  Timer
//
//  Created by Bohdan Ptyts on 04.05.2025.
//

import Foundation
import AppKit

struct KeyboardShortcut: Codable, Equatable {
    var keyCode: Int
    var modifiers: UInt
    var isEnabled: Bool
    var character: String
    
    init(keyCode: Int, modifiers: UInt, isEnabled: Bool = true, character: String = "") {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.isEnabled = isEnabled
        self.character = character
    }
    
    static func defaultShortcut() -> KeyboardShortcut {
        return KeyboardShortcut(keyCode: 35, modifiers: NSEvent.ModifierFlags.option.rawValue | NSEvent.ModifierFlags.control.rawValue, character: "P")
    }
    
    static func fromString(_ string: String) -> KeyboardShortcut? {
        return defaultShortcut()
    }
    
    func toString() -> String {
        var result = ""
        let flags = NSEvent.ModifierFlags(rawValue: modifiers)
        
        if flags.contains(.control) { result += "⌃" }
        if flags.contains(.option) { result += "⌥" }
        if flags.contains(.shift) { result += "⇧" }
        if flags.contains(.command) { result += "⌘" }
        
        result += character
        
        return result
    }
}

struct ShortcutSettings: Codable {
    var playPauseShortcut: KeyboardShortcut
    var resetTimerShortcut: KeyboardShortcut
    
    // Default settings
    static let defaultSettings = ShortcutSettings(
        playPauseShortcut: KeyboardShortcut.defaultShortcut(),
        resetTimerShortcut: KeyboardShortcut(keyCode: 37, modifiers: NSEvent.ModifierFlags.option.rawValue | NSEvent.ModifierFlags.control.rawValue, character: "L")
        )
}
