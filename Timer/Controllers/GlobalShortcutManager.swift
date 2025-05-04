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
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(shortcutSettingsDidChange),
            name: NSNotification.Name("ShortcutSettingsDidChange"),
            object: nil
        )
        
        registerShortcuts()
    }
    
    deinit {
        unregisterShortcuts()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func shortcutSettingsDidChange() {
        unregisterShortcuts()
        registerShortcuts()
    }
    
    private func registerShortcuts() {
        if appState.shortcutSettings.playPauseShortcut.isEnabled {
            registerPlayPauseShortcut()
        }
        
        if appState.shortcutSettings.resetTimerShortcut.isEnabled {
            registerResetTimerShortcut()
        }
    }
    
    private func unregisterShortcuts() {
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
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType("TIMR".utf8.reduce(0) { ($0 << 8) + OSType($1) })
        hotKeyID.id = UInt32(id)
        
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr {
            var eventType = EventTypeSpec()
            eventType.eventClass = OSType(kEventClassKeyboard)
            eventType.eventKind = OSType(kEventHotKeyPressed)
            
            let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
            
            let handlerCallback: EventHandlerUPP = { (_, eventRef, userData) -> OSStatus in
                guard let eventRef = eventRef,
                      let userData = userData else { return OSStatus(eventNotHandledErr) }
                
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
            if appState.timerState == .inactive {
                appState.timerManager.startTimer()
            } else {
                appState.timerManager.stopTimer()
            }
        case resetTimerShortcutID:
            appState.timerManager.resetTimers()
        default:
            break
        }
    }
    
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
