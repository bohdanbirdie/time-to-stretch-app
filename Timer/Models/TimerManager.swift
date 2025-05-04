//
//  TimerManager.swift
//  Timer
//
//  Created by Bohdan Ptyts on 04.05.2025.
//

import Foundation
import UserNotifications

class TimerManager {
    private weak var appState: AppState?
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    func startTimer() {
        guard let appState = appState else { return }
        
        appState.timerState = appState.timerState == .breakActive ? .breakActive : .focusActive
        
        updateAppStateTimerValue()
        
        appState.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self, let appState = self.appState else { return }
            
            if appState.timerState == .focusActive {
                if appState.focusRemainingTime > 0 {
                    appState.focusRemainingTime -= 1

                    if appState.focusRemainingTime == 0 {
                        appState.timerState = .breakActive
                        
                        self.sendFocusEndedNotification()
                    }
                    
                    self.updateAppStateTimerValue()
                }
            } else if appState.timerState == .breakActive {
                if appState.breakRemainingTime > 0 {
                    appState.breakRemainingTime -= 1
                    
                    if appState.breakRemainingTime == 0 {
                        if appState.autoCycleTimer {
                            appState.resetTimerValues()
                            appState.timerState = .focusActive
                            
                            self.updateAppStateTimerValue()
                            
                            self.sendBreakEndedNotification()
                        } else {
                            self.stopTimer()
                            self.resetTimers()
                            
                            self.sendBreakEndedNotification()
                        }
                    }
                    
                    self.updateAppStateTimerValue()
                }
            }
        }
    }
    
    func stopTimer() {
        guard let appState = appState else { return }
        
        appState.timerState = .inactive
        appState.timer?.invalidate()
        appState.timer = nil
        
        updateAppStateTimerValue()
    }
    
    func resetTimers() {
        guard let appState = appState else { return }
        
        stopTimer()
        appState.resetTimerValues()
        
        updateAppStateTimerValue()
    }
    
    func toggleTimer() {
        guard let appState = appState else { return }
        
        if appState.timerState != .inactive {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    private func updateAppStateTimerValue() {
        guard let appState = appState else { return }
        
        if appState.timerState == .breakActive {
            appState.currentTimerValue = appState.breakRemainingTime
        } else {
            appState.currentTimerValue = appState.focusRemainingTime
        }
        
        appState.timerUpdatePublisher.send(appState.currentTimerValue)
    }
    
    private func sendFocusEndedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Focus Time Ended"
        content.body = "Time for a break! Take a few minutes to relax."
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func sendBreakEndedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Break Time Ended"
        content.body = "Ready to focus again?"
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
