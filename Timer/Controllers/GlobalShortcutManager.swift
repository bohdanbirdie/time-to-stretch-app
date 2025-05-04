//
//  GlobalShortcutManager.swift
//  Timer
//
//  Created by Bohdan Ptyts on 04.05.2025.
//

import AppKit
import Carbon.HIToolbox

class GlobalShortcutManager {
    private var appState: AppState
    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private var playPauseShortcutID = 1
    private var resetTimerShortcutID = 2
    
    init(appState: AppState) {
        self.appState = appState
        
        // Register for shortcut settings changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(shortcutSettingsDidChange),
            name: NSNotification.Name("ShortcutSettingsDidChange"),
            object: nil
        )
        
        // Register shortcuts initially
        registerShortcuts()
    }
    
    deinit {
        unregisterShortcuts()
        
        // Remove observer
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func shortcutSettingsDidChange() {
        // Re-register shortcuts when settings change
        unregisterShortcuts()
        registerShortcuts()
    }
    
    private func registerShortcuts() {
        // Register the play/pause shortcut if enabled
        if appState.shortcutSettings.playPauseShortcut.isEnabled {
            registerPlayPauseShortcut()
        }
        
        // Register the reset timer shortcut if enabled
        if appState.shortcutSettings.resetTimerShortcut.isEnabled {
            registerResetTimerShortcut()
        }
    }
    
    private func unregisterShortcuts() {
        // Unregister all shortcuts
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
    
    private func registerPlayPauseShortcut() {
        let shortcut = appState.shortcutSettings.playPauseShortcut
        registerHotKey(
            keyCode: UInt32(shortcut.keyCode),
            modifiers: carbonModifiersFromCocoaModifiers(shortcut.modifiers),
            id: playPauseShortcutID
        )
    }
    
    private func registerResetTimerShortcut() {
        let shortcut = appState.shortcutSettings.resetTimerShortcut
        registerHotKey(
            keyCode: UInt32(shortcut.keyCode),
            modifiers: carbonModifiersFromCocoaModifiers(shortcut.modifiers),
            id: resetTimerShortcutID
        )
    }
    
    private func registerHotKey(keyCode: UInt32, modifiers: UInt32, id: Int) {
        // Set up the hotkey information
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType("TIMR".utf8.reduce(0) { ($0 << 8) + OSType($1) })
        hotKeyID.id = UInt32(id)
        
        // Register the hotkey
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr {
            // Set up the event handler
            var eventType = EventTypeSpec()
            eventType.eventClass = OSType(kEventClassKeyboard)
            eventType.eventKind = OSType(kEventHotKeyPressed)
            
            // Install the event handler
            let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
            
            let handlerCallback: EventHandlerUPP = { (_, eventRef, userData) -> OSStatus in
                guard let eventRef = eventRef,
                      let userData = userData else { return OSStatus(eventNotHandledErr) }
                
                // Get the hotkey ID from the event
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    eventRef,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                
                if status == noErr {
                    // Handle the hotkey event
                    let manager = Unmanaged<GlobalShortcutManager>.fromOpaque(userData).takeUnretainedValue()
                    manager.handleHotKeyEvent(Int(hotKeyID.id))
                }
                
                return OSStatus(noErr)
            }
            
            InstallEventHandler(
                GetApplicationEventTarget(),
                handlerCallback,
                1,
                &eventType,
                selfPtr,
                &eventHandler
            )
        }
    }
    
    private func handleHotKeyEvent(_ hotKeyID: Int) {
        switch hotKeyID {
        case playPauseShortcutID:
            // Toggle play/pause directly using TimerManager
            if appState.timerState == .inactive {
                appState.timerManager.startTimer()
            } else {
                appState.timerManager.stopTimer()
            }
        case resetTimerShortcutID:
            // Reset timer directly using TimerManager
            appState.timerManager.resetTimers()
        default:
            break
        }
    }
    
    // Helper function to convert Cocoa modifiers to Carbon modifiers
    private func carbonModifiersFromCocoaModifiers(_ cocoaModifiers: UInt) -> UInt32 {
        var carbonModifiers: UInt32 = 0
        
        let modifierFlags = NSEvent.ModifierFlags(rawValue: cocoaModifiers)
        
        if modifierFlags.contains(.command) {
            carbonModifiers |= UInt32(cmdKey)
        }
        if modifierFlags.contains(.option) {
            carbonModifiers |= UInt32(optionKey)
        }
        if modifierFlags.contains(.control) {
            carbonModifiers |= UInt32(controlKey)
        }
        if modifierFlags.contains(.shift) {
            carbonModifiers |= UInt32(shiftKey)
        }
        
        return carbonModifiers
    }
}
