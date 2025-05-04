//
//  ShortcutRecorderModal.swift
//  Timer
//
//  Created by Bohdan Ptyts on 04.05.2025.
//

import SwiftUI
import AppKit

struct ShortcutRecorderModal: View {
    @Binding var isPresented: Bool
    @Binding var shortcut: KeyboardShortcut
    
    // Temporary shortcut for editing
    @State private var tempShortcut: KeyboardShortcut
    // Store the original shortcut for comparison
    private let originalShortcut: KeyboardShortcut
    // State for showing conflict warning
    @State private var showConflictWarning = false
    @State private var conflictDescription = ""
    
    init(isPresented: Binding<Bool>, shortcut: Binding<KeyboardShortcut>) {
        self._isPresented = isPresented
        self._shortcut = shortcut
        // Initialize the temporary shortcut with the current value
        self._tempShortcut = State(initialValue: shortcut.wrappedValue)
        // Store the original shortcut
        self.originalShortcut = shortcut.wrappedValue
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Record Keyboard Shortcut")
                .font(.headline)
                .padding(.top, 24)
            
            Text("Press the key combination you want to use")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // Shortcut recorder with improved styling
            ZStack {
                // Background for the recorder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.windowBackgroundColor).opacity(0.6))
                    .frame(height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                
                // Shortcut recorder
                ShortcutRecorder(shortcut: $tempShortcut)
                    .frame(width: 250, height: 60)
                
                // Display the current shortcut text as a SwiftUI Text element
                // This ensures it updates properly with SwiftUI's state system
                if !tempShortcut.toString().isEmpty {
                    Text(tempShortcut.toString())
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 10)
            
            // Always show the current (original) shortcut
            Text("Current: \(originalShortcut.toString())")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Show warning if potential conflict detected
            if showConflictWarning {
                Text("⚠️ \(conflictDescription)")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            HStack(spacing: 20) {
                // Reset button on the left side
                Button("Reset") {
                    // Reset to default shortcut
                    tempShortcut = KeyboardShortcut.defaultShortcut()
                }
                .buttonStyle(BorderedButtonStyle())
                
                Spacer()
                
                // Cancel and Accept buttons grouped on the right side
                HStack(spacing: 12) {
                    Button("Cancel") {
                        // Close without saving
                        isPresented = false
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    Button("Accept") {
                        // Save the new shortcut
                        shortcut = tempShortcut
                        isPresented = false
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                    .disabled(tempShortcut.keyCode == 0 && tempShortcut.modifiers == 0)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .frame(width: 320)
        .background(Color(NSColor.windowBackgroundColor))
        .onChange(of: tempShortcut) { newValue in
            // Check for potential conflicts
            checkForConflicts(shortcut: newValue)
        }
    }
    
    // Check for potential conflicts with system shortcuts
    private func checkForConflicts(shortcut: KeyboardShortcut) {
        // Reset conflict state
        showConflictWarning = false
        conflictDescription = ""
        
        // Get the modifiers
        let modifiers = NSEvent.ModifierFlags(rawValue: shortcut.modifiers)
        
        // Known system shortcuts that might conflict
        if modifiers.contains(.option) && modifiers.contains(.command) {
            // CMD+Option combinations are often used by the system
            showConflictWarning = true
            conflictDescription = "CMD+Option combinations may be intercepted by macOS"
        }
        
        // Recommend alternatives
        if showConflictWarning {
            conflictDescription += ". Try using Control+Option instead."
        }
    }
}
