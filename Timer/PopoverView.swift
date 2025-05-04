//
//  PopoverView.swift
//  Timer
//
//  Created by Bohdan Ptyts on 01.05.2025.
//

import SwiftUI
import Combine
import UserNotifications

struct PopoverView: View {
    // Environment object to access the AppState
    @EnvironmentObject var appState: AppState
    
    // Subscription to settings changes
    @State private var settingsSubscription: AnyCancellable?
    
    // Notification observers
    @State private var notificationObservers: [NSObjectProtocol] = []
    
    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 8) {
                VStack(spacing: 5) {
                    Text("Focus")
                        .font(.headline)
                        .foregroundColor(appState.timerState == .breakActive ? .secondary : .primary)
                    
                    TimeDisplay(
                        minutes: Int(appState.focusRemainingTime) / 60,
                        seconds: Int(appState.focusRemainingTime) % 60
                    )
                    .opacity(appState.timerState == .breakActive ? 0.5 : 1.0)
                }

                VStack(spacing: 5) {
                    Text("Break")
                        .font(.headline)
                        .foregroundColor(appState.timerState == .breakActive ? .primary : .secondary)
                    
                    TimeDisplay(
                        minutes: Int(appState.breakRemainingTime) / 60,
                        seconds: Int(appState.breakRemainingTime) % 60
                    )
                    .scaleEffect(0.8)
                    .opacity(appState.timerState == .breakActive ? 1.0 : 0.5)
                }
            }

            Button(action: {
                toggleTimer()
            }) {
                Image(systemName: appState.timerState != .inactive ? "pause.fill" : "play.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(appState.timerState != .inactive ? .orange : (appState.timerState == .breakActive ? .teal : .green))
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
                .keyboardShortcut(",", modifiers: .command)
                
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
        .onAppear {
            // Set up notification observers for timer controls from menu
            setupNotificationObservers()
        }
        .onDisappear {
            // Ensure timer stops when view disappears
            if appState.timerState != .inactive {
                stopTimer()
            }
            
            // Remove notification observers
            removeNotificationObservers()
        }
    }
    
    // Timer control functions
    func toggleTimer() {
        if appState.timerState != .inactive {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    func startTimer() {
        // Set the timer state based on which timer is active
        appState.timerState = appState.timerState == .breakActive ? .breakActive : .focusActive
        
        // Update the current timer value in AppState
        updateAppStateTimerValue()
        
        appState.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if appState.timerState == .focusActive {
                // Focus timer is active
                if appState.focusRemainingTime > 0 {
                    appState.focusRemainingTime -= 1
                    
                    // When focus timer reaches zero, immediately switch to break
                    if appState.focusRemainingTime == 0 {
                        appState.timerState = .breakActive
                        
                        // Send notification when focus timer ends
                        sendFocusEndedNotification()
                    }
                    
                    // Update the current timer value in AppState
                    updateAppStateTimerValue()
                }
            } else if appState.timerState == .breakActive {
                // Break timer is active
                if appState.breakRemainingTime > 0 {
                    appState.breakRemainingTime -= 1
                    
                    // When break timer reaches zero, immediately reset and stop
                    if appState.breakRemainingTime == 0 {
                        stopTimer()
                        resetTimers()
                        
                        // Send notification when break timer ends
                        sendBreakEndedNotification()
                    }
                    
                    // Update the current timer value in AppState
                    updateAppStateTimerValue()
                }
            }
        }
    }
    
    func stopTimer() {
        appState.timerState = .inactive
        appState.timer?.invalidate()
        appState.timer = nil
        
        // Update the current timer value in AppState without resetting to 0
        // This ensures the time remains visible and in sync when paused
        updateAppStateTimerValue()
    }
    
    func resetTimers() {
        stopTimer()
        appState.resetTimerValues()
        
        // Update the current timer value in AppState
        updateAppStateTimerValue()
    }
    
    private func updateAppStateTimerValue() {
        // Update the current timer value based on which timer is active
        if appState.timerState == .breakActive {
            appState.currentTimerValue = appState.breakRemainingTime
        } else {
            appState.currentTimerValue = appState.focusRemainingTime
        }
        
        // Publish the timer update
        appState.timerUpdatePublisher.send(appState.currentTimerValue)
    }
    
    // Helper method to send a notification when focus timer ends
    private func sendFocusEndedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Focus Time Ended"
        // TODO: set dynamic type
        content.body = "Time for a break! Take 5 minutes to relax."
        content.sound = UNNotificationSound.default
        
        // Show this notification immediately
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        // Add the notification request
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            }
        }
    }
    
    // Helper method to send a notification when break timer ends
    private func sendBreakEndedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Break Time Ended"
        content.body = "Time to focus again!"
        content.sound = UNNotificationSound.default
        
        // Show this notification immediately
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        // Add the notification request
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            }
        }
    }
    
    // Setup notification observers for menu controls
    private func setupNotificationObservers() {
        // Remove any existing observers first
        removeNotificationObservers()
        
        // Start timer notification
        let startObserver = NotificationCenter.default.addObserver(
            forName: .startTimer,
            object: nil,
            queue: .main
        ) { [self] _ in
            if appState.timerState == .inactive {
                self.startTimer()
            }
        }
        
        // Stop timer notification
        let stopObserver = NotificationCenter.default.addObserver(
            forName: .stopTimer,
            object: nil,
            queue: .main
        ) { [self] _ in
            if appState.timerState != .inactive {
                self.stopTimer()
            }
        }
        
        // Reset timer notification
        let resetObserver = NotificationCenter.default.addObserver(
            forName: .resetTimer,
            object: nil,
            queue: .main
        ) { [self] _ in
            self.resetTimers()
        }
        
        // Store observers for cleanup
        notificationObservers = [startObserver, stopObserver, resetObserver]
    }
    
    // Remove notification observers
    private func removeNotificationObservers() {
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        notificationObservers = []
    }
}

#Preview {
    PopoverView()
        .environmentObject(AppState())
}
