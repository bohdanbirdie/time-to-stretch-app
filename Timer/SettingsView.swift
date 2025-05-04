//
//  SettingsView.swift
//  Timer
//
//  Created by Bohdan Ptyts on 01.05.2025.
//

import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var appState: AppState
    
    // Local state to track settings before saving
    @State private var focusHours: Int = 1
    @State private var focusMinutes: Int = 0
    @State private var breakMinutes: Int = 5
    @State private var breakSeconds: Int = 0
    
    // Tab selection state
    @State private var selectedTab: String = "App configuration"
    private let tabs = ["App configuration", "Intervals"]
    
    // Initialize state values
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // macOS-style tab bar
            Picker("", selection: $selectedTab) {
                ForEach(tabs, id: \.self) { tab in
                    Text(tab).tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            Divider()
            
            // Content based on selected tab
            ScrollView {
                if selectedTab == "App configuration" {
                    appConfigurationView
                } else {
                    intervalsView
                }
            }
        }
        .frame(width: 500, height: 400)
        .onAppear {
            // Initialize values with current settings
            let totalFocusMinutes = appState.timerSettings.focusMinutes
            focusHours = totalFocusMinutes / 60
            focusMinutes = totalFocusMinutes % 60
            breakMinutes = appState.timerSettings.breakMinutes
            breakSeconds = appState.timerSettings.breakSeconds
        }
        // Show confirmation alert when there's a pending settings change
        .sheet(isPresented: Binding<Bool>(
            get: { appState.pendingSettingsChange != nil },
            set: { if !$0 { appState.cancelPendingSettingsChange() } }
        )) {
            confirmationView
        }
    }
    
    // Confirmation view for settings changes while timer is active
    private var confirmationView: some View {
        VStack(spacing: 20) {
            Text("Reset Timer?")
                .font(.headline)
                .padding(.top, 20)
            
            Text("Changing timer settings will reset your current timer. Are you sure you want to continue?")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            HStack(spacing: 20) {
                Button("Cancel") {
                    // Cancel pending changes
                    appState.cancelPendingSettingsChange()
                    
                    // Reset UI values to current settings
                    resetUIToCurrentSettings()
                }
                .buttonStyle(BorderedButtonStyle())
                
                Button("Reset Timer") {
                    appState.confirmPendingSettingsChange()
                }
                .buttonStyle(BorderedProminentButtonStyle())
            }
            .padding(.bottom, 20)
        }
        .frame(width: 350)
    }
    
    // Custom labeled toggle component
    private struct LabeledToggle: View {
        let title: String
        @Binding var isOn: Bool
        
        var body: some View {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Toggle(title, isOn: $isOn)
                    .labelsHidden()
            }
        }
    }
    
    // Custom labeled picker component
    private struct LabeledPicker<T: Hashable & Identifiable>: View {
        let title: String
        let options: [T]
        @Binding var selection: T
        let itemLabel: (T) -> String
        
        var body: some View {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Picker(title, selection: $selection) {
                    ForEach(options) { option in
                        Text(itemLabel(option)).tag(option)
                    }
                }
                .labelsHidden()
                .frame(width: 120)
            }
        }
    }
    
    private var appConfigurationView: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            Group {
                Text("General")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                LabeledToggle(title: "Show timer text in menu bar", isOn: $appState.showTimerTextInMenuBar)
                
                LabeledToggle(title: "Auto-cycle timer", isOn: $appState.autoCycleTimer)
            }
            
            Group {
                Text("System")
                    .font(.headline)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                
                LabeledPicker(
                    title: "Appearance",
                    options: AppearanceMode.allCases,
                    selection: $appState.appearanceMode,
                    itemLabel: { $0.rawValue }
                )
                
                LabeledToggle(title: "Launch at startup", isOn: $appState.launchAtStartup)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    // Intervals Tab
    private var intervalsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            Text("Time Intervals")
                .font(.headline)
                .padding(.bottom, 4)
            
            // Time intervals group with background
            VStack(alignment: .leading, spacing: 8) {
                // Focus Duration
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Focus Duration")
                            .foregroundColor(.primary)
                        
                        Text("Min: 1 min, max: 8 hours")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8) // Align with the text field
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        // Hours
                        VStack(alignment: .center) {
                            TextField("", value: $focusHours, formatter: NumberFormatter())
                                .frame(width: 50)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: focusHours) { _ in
                                    applySettings()
                                }
                                .onSubmit {
                                    applySettings()
                                }
                            
                            Text("Hours")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Minutes
                        VStack(alignment: .center) {
                            TextField("", value: $focusMinutes, formatter: NumberFormatter())
                                .frame(width: 50)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: focusMinutes) { _ in
                                    applySettings()
                                }
                                .onSubmit {
                                    applySettings()
                                }
                            
                            Text("Minutes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Break Duration
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Break Duration")
                            .foregroundColor(.primary)
                        
                        Text("Min: 1 min, max: 1 hour")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8) // Align with the text field
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        // Minutes
                        VStack(alignment: .center) {
                            TextField("", value: $breakMinutes, formatter: NumberFormatter())
                                .frame(width: 50)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: breakMinutes) { _ in
                                    applySettings()
                                }
                                .onSubmit {
                                    applySettings()
                                }
                            
                            Text("Minutes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Seconds
                        VStack(alignment: .center) {
                            TextField("", value: $breakSeconds, formatter: NumberFormatter())
                                .frame(width: 50)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: breakSeconds) { _ in
                                    applySettings()
                                }
                                .onSubmit {
                                    applySettings()
                                }
                            
                            Text("Seconds")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Presets section
            Text("Presets")
                .font(.headline)
                .padding(.top, 8)
                .padding(.bottom, 4)
            
            // Preset buttons in a grid with background
            VStack {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    // Create buttons for each preset
                    ForEach(TimerPresets.all, id: \.name) { preset in
                        Button(action: {
                            applyPreset(preset)
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: preset.iconName)
                                    .font(.title2)
                                Text(preset.name)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .frame(height: 60)
                        }
                        .buttonStyle(BorderedButtonStyle())
                    }
                }
                .padding(8)
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    // Apply settings immediately
    private func applySettings() {
        // Calculate total focus minutes
        let totalFocusMinutes = (focusHours * 60) + focusMinutes
        
        // Ensure we have at least 1 minute and at most 8 hours for focus
        let adjustedFocusMinutes = min(8 * 60, max(1, totalFocusMinutes))
        
        // If the adjusted value is different, update the UI
        if adjustedFocusMinutes != totalFocusMinutes {
            // Recalculate hours and minutes for UI
            focusHours = adjustedFocusMinutes / 60
            focusMinutes = adjustedFocusMinutes % 60
        }
        
        // Ensure we have at least 1 minute and at most 1 hour for break
        let adjustedBreakMinutes = min(60, max(1, breakMinutes))
        
        // If the adjusted value is different, update the UI
        if adjustedBreakMinutes != breakMinutes {
            breakMinutes = adjustedBreakMinutes
            // If we had to adjust minutes, ensure seconds are 0
            if breakMinutes == 1 && breakSeconds == 0 {
                breakSeconds = 0
            }
        }
        
        // Ensure break seconds are valid (0-59)
        let adjustedBreakSeconds = min(59, max(0, breakSeconds))
        if adjustedBreakSeconds != breakSeconds {
            breakSeconds = adjustedBreakSeconds
        }
        
        // Update settings in AppState
        appState.prepareSettingsUpdate(
            focusMinutes: adjustedFocusMinutes,
            breakMinutes: adjustedBreakMinutes,
            breakSeconds: adjustedBreakSeconds
        )
    }
    
    // Apply a preset
    private func applyPreset(_ preset: TimerPreset) {
        focusHours = preset.focusHours
        focusMinutes = preset.focusMinutes
        breakMinutes = preset.breakMinutes
        breakSeconds = preset.breakSeconds
        applySettings()
    }
    
    // Reset UI values to current settings
    private func resetUIToCurrentSettings() {
        let totalFocusMinutes = appState.timerSettings.focusMinutes
        focusHours = totalFocusMinutes / 60
        focusMinutes = totalFocusMinutes % 60
        breakMinutes = appState.timerSettings.breakMinutes
        breakSeconds = appState.timerSettings.breakSeconds
    }
}

#Preview {
    SettingsView(isPresented: .constant(true))
        .environmentObject(AppState())
}
