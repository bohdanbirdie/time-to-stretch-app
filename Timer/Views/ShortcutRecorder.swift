//
//  ShortcutRecorder.swift
//  Timer
//
//  Created by Bohdan Ptyts on 04.05.2025.
//

import SwiftUI
import AppKit

// A SwiftUI wrapper for a custom NSView that can record keyboard shortcuts
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

// The actual NSView that handles the shortcut recording
class ShortcutRecorderView: NSView {
    private var shortcutBinding: Binding<KeyboardShortcut>
    private var textField: NSTextField
    private var isRecording = false
    
    init(shortcut: Binding<KeyboardShortcut>) {
        self.shortcutBinding = shortcut
        
        // Create the text field to display the shortcut
        self.textField = NSTextField()
        textField.isEditable = false
        textField.isBordered = false // Remove border
        textField.backgroundColor = .clear // Make background transparent
        textField.alignment = .center
        textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize + 8, weight: .medium) // Much larger font with medium weight
        textField.stringValue = shortcut.wrappedValue.toString()
        textField.isHidden = true // Hide the text field since we're using SwiftUI Text instead
        
        super.init(frame: NSRect(x: 0, y: 0, width: 120, height: 24))
        
        // Add the text field to the view
        addSubview(textField)
        
        // Start in recording mode
        startRecording()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layout() {
        super.layout()
        
        // Center the text field in the view
        let textSize = textField.cell?.cellSize(forBounds: bounds) ?? .zero
        let x = (bounds.width - textSize.width) / 2
        let y = (bounds.height - textSize.height) / 2
        textField.frame = NSRect(x: x, y: y, width: textSize.width, height: textSize.height)
        
        // If text is too wide, use the full width
        if textSize.width > bounds.width {
            textField.frame = NSRect(x: 0, y: y, width: bounds.width, height: textSize.height)
        }
    }
    
    func updateShortcut(_ shortcut: KeyboardShortcut) {
        // Make sure we display the full shortcut string
        textField.stringValue = shortcut.toString()
    }
    
    private func startRecording() {
        // Set recording state
        isRecording = true
        
        // Update appearance
        textField.backgroundColor = .clear // Keep transparent
        textField.stringValue = "Type shortcut..."
        textField.textColor = NSColor.secondaryLabelColor // Lighter text for placeholder
        
        // Make this view the first responder to capture key events
        window?.makeFirstResponder(self)
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        // Only process if we're recording
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        
        // Get the modifiers
        let modifiers = event.modifierFlags.intersection([.command, .control, .option, .shift])
        
        // Get the character from the event
        var keyCharacter = ""
        
        // Check if it's a special key
        if let specialKey = [36: "Return", 48: "Tab", 49: "Space", 51: "Delete", 53: "Escape", 123: "←", 124: "→", 125: "↓", 126: "↑"][Int(event.keyCode)] {
            keyCharacter = specialKey
        } else if let characters = event.charactersIgnoringModifiers?.uppercased(), !characters.isEmpty {
            // Get the character directly from the event - always use it regardless of ASCII status
            keyCharacter = String(characters.first!)
        } else {
            // Fallback for function keys
            if event.keyCode >= 96 && event.keyCode <= 111 {
                // Function keys
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
        
        // Create the new shortcut with the extracted character
        let newShortcut = KeyboardShortcut(
            keyCode: Int(event.keyCode),
            modifiers: modifiers.rawValue,
            isEnabled: shortcutBinding.wrappedValue.isEnabled,
            character: keyCharacter
        )
        
        // Update the binding
        shortcutBinding.wrappedValue = newShortcut
        
        // Update the display - force refresh by setting the text directly
        textField.stringValue = newShortcut.toString()
        textField.backgroundColor = .clear // Keep transparent
        textField.textColor = NSColor.labelColor // Reset to normal text color
        
        // Force the view to update
        self.needsDisplay = true
    }
}
