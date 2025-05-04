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
    @EnvironmentObject var appState: AppState
    
    @State private var settingsSubscription: AnyCancellable?
    
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
            setupNotificationObservers()
        }
        .onDisappear {
            if appState.timerState != .inactive {
                stopTimer()
            }
            removeNotificationObservers()
        }
    }
    
    func toggleTimer() {
        appState.timerManager.toggleTimer()
    }
    
    func startTimer() {
        appState.timerManager.startTimer()
    }
    
    func stopTimer() {
        appState.timerManager.stopTimer()
    }
    
    func resetTimers() {
        appState.timerManager.resetTimers()
    }
    
    private func updateAppStateTimerValue() {
    }
    
    private func sendFocusEndedNotification() {
    }
    
    private func sendBreakEndedNotification() {
    }
    
    private func setupNotificationObservers() {
        removeNotificationObservers()
        
        let startObserver = NotificationCenter.default.addObserver(
            forName: .startTimer,
            object: nil,
            queue: .main
        ) { [self] _ in
            if appState.timerState == .inactive {
                self.startTimer()
            }
        }
        
        let stopObserver = NotificationCenter.default.addObserver(
            forName: .stopTimer,
            object: nil,
            queue: .main
        ) { [self] _ in
            if appState.timerState != .inactive {
                self.stopTimer()
            }
        }
        
        let resetObserver = NotificationCenter.default.addObserver(
            forName: .resetTimer,
            object: nil,
            queue: .main
        ) { [self] _ in
            self.resetTimers()
        }
        
        notificationObservers = [startObserver, stopObserver, resetObserver]
    }
    
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
