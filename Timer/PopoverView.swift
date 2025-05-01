//
//  PopoverView.swift
//  Timer
//
//  Created by Bohdan Ptyts on 01.05.2025.
//

import SwiftUI
import Combine

struct PopoverView: View {
    // Environment object to access the AppState
    @EnvironmentObject var appState: AppState
    
    // Timer states
    @State private var timerRunning = false
    @State private var focusRemainingTime: TimeInterval = 60 * 60 // 60 minutes
    @State private var breakRemainingTime: TimeInterval = 5 * 60 // 5 minutes
    @State private var isBreakActive = false // Tracks which timer is currently active
    
    // Timer settings
    @State private var focusDuration: TimeInterval = 60 * 60 // 60 minutes
    @State private var breakDuration: TimeInterval = 5 * 60 // 5 minutes
    
    // Timer instance
    @State private var timer: Timer? = nil
    
    // Subscription to settings changes
    @State private var settingsSubscription: AnyCancellable?
    
    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 8) {
                VStack(spacing: 5) {
                    Text("Focus")
                        .font(.headline)
                        .foregroundColor(isBreakActive ? .secondary : .primary)
                    
                    TimeDisplay(
                        minutes: Int(focusRemainingTime) / 60,
                        seconds: Int(focusRemainingTime) % 60
                    )
                    .opacity(isBreakActive ? 0.5 : 1.0)
                }

                VStack(spacing: 5) {
                    Text("Break")
                        .font(.headline)
                        .foregroundColor(isBreakActive ? .primary : .secondary)
                    
                    TimeDisplay(
                        minutes: Int(breakRemainingTime) / 60,
                        seconds: Int(breakRemainingTime) % 60
                    )
                    .scaleEffect(0.8)
                    .opacity(isBreakActive ? 1.0 : 0.5)
                }
            }

            Button(action: {
                toggleTimer()
            }) {
                Image(systemName: timerRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(timerRunning ? .orange : (isBreakActive ? .teal : .green))
                    .frame(width: 60, height: 60)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(width: 200, height: 240)
        .overlay(
            HStack {
                Button(action: {
                    appState.openSettings()
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button(action: {
                    resetTimers()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10),
            alignment: .bottom
        )
        .onDisappear {
            // Ensure timer stops when view disappears
            if timerRunning {
                stopTimer()
            }
            
            // Cancel subscription
            settingsSubscription?.cancel()
        }
        .onAppear {
            // Initialize with current settings
            updateDurations(
                focusMinutes: appState.timerSettings.focusMinutes,
                breakMinutes: appState.timerSettings.breakMinutes,
                breakSeconds: appState.timerSettings.breakSeconds
            )
            
            // Subscribe to settings changes
            settingsSubscription = appState.settingsChangedPublisher
                .sink { newSettings in
                    // Stop the timer and reset with new durations
                    stopTimer()
                    updateDurations(
                        focusMinutes: newSettings.focusMinutes,
                        breakMinutes: newSettings.breakMinutes,
                        breakSeconds: newSettings.breakSeconds
                    )
                }
        }
    }
    
    // Timer control functions
    func toggleTimer() {
        if timerRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    func startTimer() {
        timerRunning = true
        appState.isTimerActive = true
        appState.isBreakActive = isBreakActive
        
        // Update the current timer value in AppState
        updateAppStateTimerValue()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if !isBreakActive {
                // Focus timer is active
                if focusRemainingTime > 0 {
                    focusRemainingTime -= 1
                    
                    // When focus timer reaches zero, immediately switch to break
                    if focusRemainingTime == 0 {
                        isBreakActive = true
                        appState.isBreakActive = true
                    }
                    
                    // Update the current timer value in AppState
                    updateAppStateTimerValue()
                }
            } else {
                // Break timer is active
                if breakRemainingTime > 0 {
                    breakRemainingTime -= 1
                    
                    // When break timer reaches zero, immediately reset and stop
                    if breakRemainingTime == 0 {
                        stopTimer()
                        resetTimers()
                    }
                    
                    // Update the current timer value in AppState
                    updateAppStateTimerValue()
                }
            }
        }
    }
    
    func stopTimer() {
        timerRunning = false
        appState.isTimerActive = false
        timer?.invalidate()
        timer = nil
        
        // Clear the timer value in AppState
        appState.currentTimerValue = 0
        appState.timerUpdatePublisher.send(0)
    }
    
    func resetTimers() {
        stopTimer()
        isBreakActive = false
        focusRemainingTime = focusDuration
        breakRemainingTime = breakDuration
    }
    
    // Update duration settings and reset timers
    func updateDurations(focusMinutes: Int, breakMinutes: Int, breakSeconds: Int = 0) {
        focusDuration = TimeInterval(focusMinutes * 60)
        breakDuration = TimeInterval(breakMinutes * 60 + breakSeconds)
        resetTimers()
    }
    
    // Helper method to update the AppState with current timer value
    private func updateAppStateTimerValue() {
        let currentValue = isBreakActive ? breakRemainingTime : focusRemainingTime
        appState.currentTimerValue = currentValue
        appState.timerUpdatePublisher.send(currentValue)
    }
}

#Preview {
    PopoverView()
        .environmentObject(AppState())
}
