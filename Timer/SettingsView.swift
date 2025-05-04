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
    
    @State private var focusHours: Int = 1
    @State private var focusMinutes: Int = 0
    @State private var breakMinutes: Int = 5
    @State private var breakSeconds: Int = 0
    
    @State private var selectedTab: String = "App configuration"
    private let tabs = ["App configuration", "Intervals", "Shortcuts", "About"]
    
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    var body: some View {
        VStack(spacing: 0) {
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
            
            ScrollView {
                if selectedTab == "App configuration" {
                    appConfigurationView
                } else if selectedTab == "Intervals" {
                    intervalsView
                } else if selectedTab == "Shortcuts" {
                    shortcutsView
                } else {
                    aboutView
                }
            }
        }
        .frame(width: 500, height: 400)
        .onAppear {
            let totalFocusMinutes = appState.timerSettings.focusMinutes
            focusHours = totalFocusMinutes / 60
            focusMinutes = totalFocusMinutes % 60
            breakMinutes = appState.timerSettings.breakMinutes
            breakSeconds = appState.timerSettings.breakSeconds
        }
        .sheet(isPresented: Binding<Bool>(
            get: { appState.pendingSettingsChange != nil },
            set: { if !$0 { appState.cancelPendingSettingsChange() } }
        )) {
            confirmationView
        }
        .sheet(isPresented: $showShortcutRecorder) {
            ShortcutRecorderModal(
                isPresented: $showShortcutRecorder,
                shortcut: Binding(
                    get: { self.tempShortcut },
                    set: { newValue in
                        self.tempShortcut = newValue
                        
                        switch tempShortcutType {
                        case .playPause:
                            self.appState.shortcutSettings.playPauseShortcut = newValue
                        case .resetTimer:
                            self.appState.shortcutSettings.resetTimerShortcut = newValue
                        }
                    }
                )
            )
        }
    }
    
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
                    appState.cancelPendingSettingsChange()
                    
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
    
    private var intervalsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Time Intervals")
                .font(.headline)
                .padding(.bottom, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Focus Duration")
                            .foregroundColor(.primary)
                        
                        Text("Min: 1 min, max: 8 hours")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8) 
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
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
                
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Break Duration")
                            .foregroundColor(.primary)
                        
                        Text("Min: 1 min, max: 1 hour")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8) 
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
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
            
            Text("Presets")
                .font(.headline)
                .padding(.top, 8)
                .padding(.bottom, 4)
            
            VStack {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
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
    
    private var shortcutsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Keyboard Shortcuts")
                .font(.headline)
                .padding(.bottom, 4)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Play/Pause Timer")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        tempShortcutType = .playPause
                        tempShortcut = appState.shortcutSettings.playPauseShortcut
                        showShortcutRecorder = true
                    }) {
                        Text(appState.shortcutSettings.playPauseShortcut.toString().isEmpty ? "Not Set" : appState.shortcutSettings.playPauseShortcut.toString())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!appState.shortcutSettings.playPauseShortcut.isEnabled)
                    
                    Toggle("", isOn: $appState.shortcutSettings.playPauseShortcut.isEnabled)
                        .labelsHidden()
                }
                
                HStack {
                    Text("Reset Timer")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        tempShortcutType = .resetTimer
                        tempShortcut = appState.shortcutSettings.resetTimerShortcut
                        showShortcutRecorder = true
                    }) {
                        Text(appState.shortcutSettings.resetTimerShortcut.toString().isEmpty ? "Not Set" : appState.shortcutSettings.resetTimerShortcut.toString())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!appState.shortcutSettings.resetTimerShortcut.isEnabled)
                    
                    Toggle("", isOn: $appState.shortcutSettings.resetTimerShortcut.isEnabled)
                        .labelsHidden()
                }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Text("Note: Changes to shortcuts take effect immediately. You may need to restart the app if shortcuts don't work properly.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .onAppear {
            tempShortcut = appState.shortcutSettings.playPauseShortcut
        }
    }
    
    private var aboutView: some View {
        VStack(spacing: 20) {
            // App Icon
            Image("AppIcon")
                    .resizable()
                    .frame(width: 128, height: 128)
                .cornerRadius(16)
                    .padding(.top, 20)
            
            // App Name
            Text("Time to stretch")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Link("GitHub Repository", destination: URL(string: "https://github.com/bohdanbirdie/time-to-stretch-app")!)
                    .buttonStyle(LinkButtonStyle())
                
                Link("Developer: @bohdanbirdie", destination: URL(string: "https://github.com/bohdanbirdie")!)
                    .buttonStyle(LinkButtonStyle())
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
    
    private struct LinkButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(configuration.isPressed ? 0.7 : 0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        }
    }
    
    @State private var showShortcutRecorder = false
    @State private var tempShortcut = KeyboardShortcut(keyCode: 35, modifiers: NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.control.rawValue)
    @State private var tempShortcutType: ShortcutType = .playPause
    
    private enum ShortcutType {
        case playPause
        case resetTimer
    }
    
    private func applySettings() {
        let totalFocusMinutes = (focusHours * 60) + focusMinutes
        
        let adjustedFocusMinutes = min(8 * 60, max(1, totalFocusMinutes))
        
        if adjustedFocusMinutes != totalFocusMinutes {
            focusHours = adjustedFocusMinutes / 60
            focusMinutes = adjustedFocusMinutes % 60
        }
        
        let adjustedBreakMinutes = min(60, max(1, breakMinutes))
        
        if adjustedBreakMinutes != breakMinutes {
            breakMinutes = adjustedBreakMinutes
            if breakMinutes == 1 && breakSeconds == 0 {
                breakSeconds = 0
            }
        }
        
        let adjustedBreakSeconds = min(59, max(0, breakSeconds))
        if adjustedBreakSeconds != breakSeconds {
            breakSeconds = adjustedBreakSeconds
        }
        
        appState.prepareSettingsUpdate(
            focusMinutes: adjustedFocusMinutes,
            breakMinutes: adjustedBreakMinutes,
            breakSeconds: adjustedBreakSeconds
        )
    }
    
    private func applyPreset(_ preset: TimerPreset) {
        focusHours = preset.focusHours
        focusMinutes = preset.focusMinutes
        breakMinutes = preset.breakMinutes
        breakSeconds = preset.breakSeconds
        applySettings()
    }
    
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
