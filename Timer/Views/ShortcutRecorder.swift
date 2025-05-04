//
//  ShortcutRecorder.swift
//  Timer
//
//  Created by Bohdan Ptyts on 04.05.2025.
//

import SwiftUI
import AppKit

struct ShortcutRecorder: NSViewRepresentable {
    @Binding var shortcut: KeyboardShortcut
    
    func makeNSView(context: Context) -> ShortcutRecorderView {
        let view = ShortcutRecorderView(shortcut: $shortcut)
        return view
    }
    
    func updateNSView(_ nsView: ShortcutRecorderView, context: Context) {
        nsView.updateShortcut(shortcut)
    }
}

class ShortcutRecorderView: NSView {
    private var shortcutBinding: Binding<KeyboardShortcut>
    private var textField: NSTextField
    private var isRecording = false
    
    init(shortcut: Binding<KeyboardShortcut>) {
        self.shortcutBinding = shortcut
        
        self.textField = NSTextField()
        textField.isEditable = false
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.alignment = .center
        textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize + 8, weight: .medium)
        textField.stringValue = shortcut.wrappedValue.toString()
        textField.isHidden = true
        
        super.init(frame: NSRect(x: 0, y: 0, width: 120, height: 24))
        
        addSubview(textField)
        
        startRecording()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layout() {
        super.layout()
        
        let textSize = textField.cell?.cellSize(forBounds: bounds) ?? .zero
        let x = (bounds.width - textSize.width) / 2
        let y = (bounds.height - textSize.height) / 2
        textField.frame = NSRect(x: x, y: y, width: textSize.width, height: textSize.height)
        
        if textSize.width > bounds.width {
            textField.frame = NSRect(x: 0, y: y, width: bounds.width, height: textSize.height)
        }
    }
    
    func updateShortcut(_ shortcut: KeyboardShortcut) {
        textField.stringValue = shortcut.toString()
    }
    
    private func startRecording() {
        isRecording = true
        
        textField.backgroundColor = .clear
        textField.stringValue = "Type shortcut..."
        textField.textColor = NSColor.secondaryLabelColor
        
        window?.makeFirstResponder(self)
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        
        let modifiers = event.modifierFlags.intersection([.command, .control, .option, .shift])
        
        var keyCharacter = ""
        
        if let specialKey = [36: "Return", 48: "Tab", 49: "Space", 51: "Delete", 53: "Escape", 123: "←", 124: "→", 125: "↓", 126: "↑"][Int(event.keyCode)] {
            keyCharacter = specialKey
        } else if let characters = event.charactersIgnoringModifiers?.uppercased(), !characters.isEmpty {
            keyCharacter = String(characters.first!)
        } else {
            if event.keyCode >= 96 && event.keyCode <= 111 {
                let functionKeyNumber = [
                    96: 5, 97: 6, 98: 7, 99: 3, 100: 8, 101: 9,
                    103: 11, 109: 10, 111: 12, 105: 13, 107: 14, 113: 15,
                    106: 16, 64: 17, 79: 18, 80: 19, 90: 20
                ][Int(event.keyCode)]
                
                if let number = functionKeyNumber {
                    keyCharacter = "F\(number)"
                }
            }
            
            // Last resort fallback
            if keyCharacter.isEmpty {
                keyCharacter = "Key(\(event.keyCode))"
            }
        }
        
        let newShortcut = KeyboardShortcut(
            keyCode: Int(event.keyCode),
            modifiers: modifiers.rawValue,
            isEnabled: shortcutBinding.wrappedValue.isEnabled,
            character: keyCharacter
        )
        
        shortcutBinding.wrappedValue = newShortcut
        
        textField.stringValue = newShortcut.toString()
        textField.backgroundColor = .clear
        textField.textColor = NSColor.labelColor
        
        self.needsDisplay = true
    }
}
