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
    
    @State private var tempShortcut: KeyboardShortcut
    private let originalShortcut: KeyboardShortcut
    @State private var showConflictWarning = false
    @State private var conflictDescription = ""
    
    init(isPresented: Binding<Bool>, shortcut: Binding<KeyboardShortcut>) {
        self._isPresented = isPresented
        self._shortcut = shortcut
        self._tempShortcut = State(initialValue: shortcut.wrappedValue)
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
            
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.windowBackgroundColor).opacity(0.6))
                    .frame(height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                
                ShortcutRecorder(shortcut: $tempShortcut)
                    .frame(width: 250, height: 60)
                
                if !tempShortcut.toString().isEmpty {
                    Text(tempShortcut.toString())
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 10)
            
            Text("Current: \(originalShortcut.toString())")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if showConflictWarning {
                Text("⚠️ \(conflictDescription)")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            HStack(spacing: 20) {
                Button("Reset") {
                    tempShortcut = KeyboardShortcut.defaultShortcut()
                }
                .buttonStyle(BorderedButtonStyle())
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    Button("Accept") {
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
            checkForConflicts(shortcut: newValue)
        }
    }
    
    private func checkForConflicts(shortcut: KeyboardShortcut) {
        showConflictWarning = false
        conflictDescription = ""
        
        let modifiers = NSEvent.ModifierFlags(rawValue: shortcut.modifiers)
        
        if modifiers.contains(.option) && modifiers.contains(.command) {
            showConflictWarning = true
            conflictDescription = "CMD+Option combinations may be intercepted by macOS"
        }
        
        if showConflictWarning {
            conflictDescription += ". Try using Control+Option instead."
        }
    }
}
