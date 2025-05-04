//
//  ShortcutSettings.swift
//  Timer
//
//  Created by Bohdan Ptyts on 04.05.2025.
//

import Foundation
import AppKit

// Represents a keyboard shortcut
struct KeyboardShortcut: Codable, Equatable {
    var keyCode: Int
    var modifiers: UInt
    var isEnabled: Bool
    var character: String
    
    // Default initializer
    init(keyCode: Int, modifiers: UInt, isEnabled: Bool = true, character: String = "") {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.isEnabled = isEnabled
        self.character = character
    }
    
    // Default shortcut for play/pause
    static func defaultShortcut() -> KeyboardShortcut {
        return KeyboardShortcut(keyCode: 35, modifiers: NSEvent.ModifierFlags.option.rawValue | NSEvent.ModifierFlags.control.rawValue, character: "P")
    }
    
    // This method is a placeholder - would need to be implemented for actual string parsing
    // Currently not used in the app
    static func fromString(_ string: String) -> KeyboardShortcut? {
        // For future implementation - parse a string representation into a shortcut
        return defaultShortcut()
    }
    
    // Convert to a human-readable string
    func toString() -> String {
        var result = ""
        let flags = NSEvent.ModifierFlags(rawValue: modifiers)
        
        if flags.contains(.control) { result += "⌃" }
        if flags.contains(.option) { result += "⌥" }
        if flags.contains(.shift) { result += "⇧" }
        if flags.contains(.command) { result += "⌘" }
        
        // Use the stored character
        result += character
        
        return result
    }
}

// Struct to hold all shortcut settings
struct ShortcutSettings: Codable {
    var playPauseShortcut: KeyboardShortcut
    var resetTimerShortcut: KeyboardShortcut
    
    // Default settings
    static let defaultSettings = ShortcutSettings(
        playPauseShortcut: KeyboardShortcut.defaultShortcut(),
        resetTimerShortcut: KeyboardShortcut(keyCode: 37, modifiers: NSEvent.ModifierFlags.option.rawValue | NSEvent.ModifierFlags.control.rawValue, character: "L")
    )
}
