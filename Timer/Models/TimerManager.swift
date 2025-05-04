//
//  TimerManager.swift
//  Timer
//
//  Created by Bohdan Ptyts on 04.05.2025.
//

import Foundation
import UserNotifications

class TimerManager {
    // Reference to AppState
    private weak var appState: AppState?
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    // Start the timer
    func startTimer() {
        guard let appState = appState else { return }
        
        // Set the timer state based on which timer is active
        appState.timerState = appState.timerState == .breakActive ? .breakActive : .focusActive
        
        // Update the current timer value in AppState
        updateAppStateTimerValue()
        
        appState.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self, let appState = self.appState else { return }
            
            if appState.timerState == .focusActive {
                // Focus timer is active
                if appState.focusRemainingTime > 0 {
                    appState.focusRemainingTime -= 1
                    
                    // When focus timer reaches zero, immediately switch to break
                    if appState.focusRemainingTime == 0 {
                        appState.timerState = .breakActive
                        
                        // Send notification when focus timer ends
                        self.sendFocusEndedNotification()
                    }
                    
                    // Update the current timer value in AppState
                    self.updateAppStateTimerValue()
                }
            } else if appState.timerState == .breakActive {
                // Break timer is active
                if appState.breakRemainingTime > 0 {
                    appState.breakRemainingTime -= 1
                    
                    if appState.breakRemainingTime == 0 {
                        if appState.autoCycleTimer {
                            // Reset timers but keep running
                            appState.resetTimerValues()
                            appState.timerState = .focusActive
                            
                            // Update the current timer value in AppState
                            self.updateAppStateTimerValue()
                            
                            // Send notification when break timer ends and new focus begins
                            self.sendBreakEndedNotification()
                        } else {
                            // Traditional behavior - stop timer
                            self.stopTimer()
                            self.resetTimers()
                            
                            // Send notification when break timer ends
                            self.sendBreakEndedNotification()
                        }
                    }
                    
                    // Update the current timer value in AppState
                    self.updateAppStateTimerValue()
                }
            }
        }
    }
    
    // Stop the timer
    func stopTimer() {
        guard let appState = appState else { return }
        
        appState.timerState = .inactive
        appState.timer?.invalidate()
        appState.timer = nil
        
        // Update the current timer value in AppState without resetting to 0
        // This ensures the time remains visible and in sync when paused
        updateAppStateTimerValue()
    }
    
    // Reset timers to their initial values
    func resetTimers() {
        guard let appState = appState else { return }
        
        stopTimer()
        appState.resetTimerValues()
        
        // Update the current timer value in AppState
        updateAppStateTimerValue()
    }
    
    // Toggle timer between running and stopped states
    func toggleTimer() {
        guard let appState = appState else { return }
        
        if appState.timerState != .inactive {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    // Update the current timer value in AppState
    private func updateAppStateTimerValue() {
        guard let appState = appState else { return }
        
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
        content.body = "Time for a break! Take a few minutes to relax."
        content.sound = UNNotificationSound.default
        
        // Show this notification immediately
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // Helper method to send a notification when break timer ends
    private func sendBreakEndedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Break Time Ended"
        content.body = "Ready to focus again?"
        content.sound = UNNotificationSound.default
        
        // Show this notification immediately
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
