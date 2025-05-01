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
    @State private var selectedTab: String = "General"
    private let tabs = ["General", "Intervals"]
    
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
                if selectedTab == "General" {
                    generalView
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
    }
    
    // General Settings Tab
    private var generalView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Appearance")
                .font(.headline)
                .padding(.top)
            
            Toggle("Launch at startup", isOn: .constant(false))
            
            Toggle("Show timer in menu bar", isOn: .constant(true))
            
            Toggle("Skip break if idle", isOn: .constant(true))
            
            Toggle("Auto-start timer", isOn: .constant(false))
            
            Toggle("Show task \"Other\"", isOn: .constant(true))
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // Intervals Tab
    private var intervalsView: some View {
        VStack {
            VStack(alignment: .leading, spacing: 20) {
                // Focus duration time input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Focus Duration")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 20) {
                        // Hours Picker
                        VStack(alignment: .center) {
                            Picker("Hours", selection: $focusHours) {
                                ForEach(0..<3) { hour in
                                    Text("\(hour)").tag(hour)
                                }
                            }
                            .labelsHidden()
                            .onChange(of: focusHours) { _ in
                                applySettings()
                            }
                            
                            Text("Hours")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Minutes Picker
                        VStack(alignment: .center) {
                            Picker("Minutes", selection: $focusMinutes) {
                                ForEach(0..<60) { minute in
                                    Text(String(format: "%02d", minute)).tag(minute)
                                }
                            }
                            .labelsHidden()
                            .onChange(of: focusMinutes) { _ in
                                applySettings()
                            }
                            
                            Text("Minutes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal)
                
                // Break duration time input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Break Duration")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 20) {
                        // Minutes Picker
                        VStack(alignment: .center) {
                            Picker("Minutes", selection: $breakMinutes) {
                                ForEach(0..<61) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .labelsHidden()
                            .onChange(of: breakMinutes) { _ in
                                applySettings()
                            }
                            
                            Text("Minutes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Seconds Picker
                        VStack(alignment: .center) {
                            Picker("Seconds", selection: $breakSeconds) {
                                ForEach(0..<60) { second in
                                    Text(String(format: "%02d", second)).tag(second)
                                }
                            }
                            .labelsHidden()
                            .onChange(of: breakSeconds) { _ in
                                applySettings()
                            }
                            
                            Text("Seconds")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
        }
    }
    
    // Apply settings immediately
    private func applySettings() {
        // Calculate total focus minutes
        let totalFocusMinutes = (focusHours * 60) + focusMinutes
        // Ensure we have at least 1 minute for focus
        let adjustedFocusMinutes = max(1, totalFocusMinutes)
        
        // Ensure we have at least some break time if minutes are 0
        let adjustedBreakMinutes = breakMinutes
        let adjustedBreakSeconds = (breakMinutes == 0 && breakSeconds == 0) ? 30 : breakSeconds
        
        // Update settings in AppState
        appState.updateTimerSettings(
            focusMinutes: adjustedFocusMinutes,
            breakMinutes: adjustedBreakMinutes,
            breakSeconds: adjustedBreakSeconds
        )
    }
}

#Preview {
    SettingsView(isPresented: .constant(true))
        .environmentObject(AppState())
}
