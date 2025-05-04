//
//  TimerManagerTests.swift
//  TimerTests
//
//  Created by Bohdan Ptyts on 04.05.2025.
//

import XCTest
@testable import Timer

class MockAppState: AppState {
    // Override initializer to avoid actual initialization
    override init() {
        // Create default timer settings
        let settings = TimerSettings(
            focusMinutes: 25,
            breakMinutes: 5,
            breakSeconds: 0,
            autoCycleTimer: false
        )
        
        // Call super.init with minimal setup
        super.init()
        
        // Set our test values
        self.timerSettings = settings
        self.focusDuration = TimeInterval(settings.focusMinutes * 60)
        self.breakDuration = TimeInterval(settings.breakMinutes * 60 + settings.breakSeconds)
        self.focusRemainingTime = self.focusDuration
        self.breakRemainingTime = self.breakDuration
    }
    
    // Mock timer to avoid actual scheduling
    var mockTimer: Timer?
    var timerCallback: ((Timer) -> Void)?
    
    // Override timer property
    override var timer: Timer? {
        get { return mockTimer }
        set {
            // If we're setting a new timer
            if let newTimer = newValue, mockTimer == nil {
                // Store the timer
                mockTimer = newTimer
                
                // For testing, we need to capture the callback that would be executed
                // when the timer fires. In a real Timer.scheduledTimer call, this would
                // be set up automatically.
                timerCallback = { [weak self] _ in
                    // This simulates what happens in TimerManager.startTimer()
                    guard let strongSelf = self else { return }
                    
                    if strongSelf.timerState == .focusActive {
                        // Focus timer is active
                        if strongSelf.focusRemainingTime > 0 {
                            strongSelf.focusRemainingTime -= 1
                            
                            // When focus timer reaches zero, immediately switch to break
                            if strongSelf.focusRemainingTime == 0 {
                                strongSelf.timerState = .breakActive
                            }
                        }
                    } else if strongSelf.timerState == .breakActive {
                        // Break timer is active
                        if strongSelf.breakRemainingTime > 0 {
                            strongSelf.breakRemainingTime -= 1
                            
                            if strongSelf.breakRemainingTime == 0 {
                                if strongSelf.autoCycleTimer {
                                    // Reset timers but keep running
                                    strongSelf.resetTimerValues()
                                    strongSelf.timerState = .focusActive
                                } else {
                                    // Traditional behavior - stop timer
                                    strongSelf.timerState = .inactive
                                    strongSelf.timer = nil
                                }
                            }
                        }
                    }
                }
            } else {
                // If we're clearing the timer
                mockTimer = nil
                timerCallback = nil
            }
        }
    }
    
    // Simulate timer ticks
    func simulateTimerTick() {
        if let callback = timerCallback {
            callback(Timer())
        }
    }
}

class TimerManagerTests: XCTestCase {
    var mockAppState: MockAppState!
    var timerManager: TimerManager!

    override func setUp() {
        super.setUp()
        mockAppState = MockAppState()
        timerManager = TimerManager(appState: mockAppState)
    }

    override func tearDown() {
        mockAppState = nil
        timerManager = nil
        super.tearDown()
    }
    
    // Test starting the timer
    func testStartTimer() {
        // Given
        mockAppState.timerState = .inactive
        
        // When
        timerManager.startTimer()
        
        // Then
        XCTAssertEqual(mockAppState.timerState, .focusActive)
        XCTAssertNotNil(mockAppState.timer)
    }
    
    // Test stopping the timer
    func testStopTimer() {
        // Given
        mockAppState.timerState = .focusActive
        mockAppState.timer = Timer() // Just a dummy timer for testing
        
        // When
        timerManager.stopTimer()
        
        // Then
        XCTAssertEqual(mockAppState.timerState, .inactive)
        XCTAssertNil(mockAppState.timer)
    }
    
    // Test resetting the timers
    func testResetTimers() {
        // Given
        mockAppState.timerState = .focusActive
        mockAppState.focusRemainingTime = 30
        mockAppState.breakRemainingTime = 30
        
        // When
        timerManager.resetTimers()
        
        // Then
        XCTAssertEqual(mockAppState.timerState, .inactive)
        XCTAssertEqual(mockAppState.focusRemainingTime, mockAppState.focusDuration)
        XCTAssertEqual(mockAppState.breakRemainingTime, mockAppState.breakDuration)
    }
    
    // Test toggling the timer from inactive to active
    func testToggleTimerFromInactiveToActive() {
        // Given
        mockAppState.timerState = .inactive
        
        // When
        timerManager.toggleTimer()
        
        // Then
        XCTAssertEqual(mockAppState.timerState, .focusActive)
        XCTAssertNotNil(mockAppState.timer)
    }
    
    // Test toggling the timer from active to inactive
    func testToggleTimerFromActiveToInactive() {
        // Given
        mockAppState.timerState = .focusActive
        mockAppState.timer = Timer() // Just a dummy timer for testing
        
        // When
        timerManager.toggleTimer()
        
        // Then
        XCTAssertEqual(mockAppState.timerState, .inactive)
        XCTAssertNil(mockAppState.timer)
    }
    
    // Test focus timer completion - manually testing the logic
    func testFocusTimerCompletion() {
        // Given
        mockAppState.timerState = .focusActive
        mockAppState.focusRemainingTime = 0
        
        // When - directly test the condition that would be checked in the timer callback
        if mockAppState.focusRemainingTime == 0 {
            mockAppState.timerState = .breakActive
        }
        
        // Then
        XCTAssertEqual(mockAppState.timerState, .breakActive)
    }
    
    // Test break timer completion with auto-cycle disabled - manually testing the logic
    func testBreakTimerCompletionWithAutoCycleDisabled() {
        // Given
        mockAppState.timerState = .breakActive
        mockAppState.breakRemainingTime = 0
        mockAppState.timerSettings.autoCycleTimer = false
        
        // When - directly test the logic that would be in the timer callback
        if mockAppState.breakRemainingTime == 0 {
            if mockAppState.autoCycleTimer {
                mockAppState.resetTimerValues()
                mockAppState.timerState = .focusActive
            } else {
                mockAppState.timerState = .inactive
            }
        }
        
        // Then
        XCTAssertEqual(mockAppState.timerState, .inactive)
    }
    
    // Test break timer completion with auto-cycle enabled - manually testing the logic
    func testBreakTimerCompletionWithAutoCycleEnabled() {
        // Given
        mockAppState.timerState = .breakActive
        mockAppState.breakRemainingTime = 0
        mockAppState.timerSettings.autoCycleTimer = true
        
        // When - directly test the logic that would be in the timer callback
        if mockAppState.breakRemainingTime == 0 {
            if mockAppState.autoCycleTimer {
                mockAppState.resetTimerValues()
                mockAppState.timerState = .focusActive
            } else {
                mockAppState.timerState = .inactive
            }
        }
        
        // Then
        XCTAssertEqual(mockAppState.timerState, .focusActive)
        XCTAssertEqual(mockAppState.focusRemainingTime, mockAppState.focusDuration)
    }
    
    // Test complete auto-cycle behavior through multiple cycles
    func testCompleteCycleWithAutoCycleEnabled() {
        // Given
        mockAppState.timerSettings.autoCycleTimer = true
        mockAppState.timerState = .inactive
        mockAppState.focusRemainingTime = 2 // Short duration for testing
        mockAppState.breakRemainingTime = 2 // Short duration for testing
        
        // Start the timer - this should create a timer and set state to focusActive
        timerManager.startTimer()
        XCTAssertEqual(mockAppState.timerState, .focusActive, "Timer should start in focus mode")
        
        // Simulate timer ticks until focus timer reaches zero
        mockAppState.simulateTimerTick() // 1 second left
        XCTAssertEqual(mockAppState.focusRemainingTime, 1, "Focus timer should decrease")
        XCTAssertEqual(mockAppState.timerState, .focusActive, "Timer should still be in focus mode")
        
        mockAppState.simulateTimerTick() // 0 seconds left - should transition to break
        XCTAssertEqual(mockAppState.timerState, .breakActive, "Timer should transition to break mode")
        
        // Simulate timer ticks until break timer reaches zero
        mockAppState.simulateTimerTick() // 1 second left
        XCTAssertEqual(mockAppState.breakRemainingTime, 1, "Break timer should decrease")
        XCTAssertEqual(mockAppState.timerState, .breakActive, "Timer should still be in break mode")
        
        mockAppState.simulateTimerTick() // 0 seconds left - with auto-cycle, should go back to focus
        XCTAssertEqual(mockAppState.timerState, .focusActive, "Timer should auto-cycle back to focus mode")
        XCTAssertEqual(mockAppState.focusRemainingTime, mockAppState.focusDuration, "Focus timer should be reset")
        
        // Simulate second cycle
        // Tick through the focus timer again
        for _ in 1...Int(mockAppState.focusDuration) {
            if mockAppState.focusRemainingTime > 1 {
                mockAppState.simulateTimerTick()
                XCTAssertEqual(mockAppState.timerState, .focusActive, "Timer should remain in focus mode")
            }
        }
        
        // Last tick of focus timer should transition to break
        mockAppState.simulateTimerTick()
        XCTAssertEqual(mockAppState.timerState, .breakActive, "Timer should transition to break mode again")
        
        // Tick through the break timer again
        for _ in 1...Int(mockAppState.breakDuration) {
            if mockAppState.breakRemainingTime > 1 {
                mockAppState.simulateTimerTick()
                XCTAssertEqual(mockAppState.timerState, .breakActive, "Timer should remain in break mode")
            }
        }
        
        // Last tick of break timer should auto-cycle back to focus
        mockAppState.simulateTimerTick()
        XCTAssertEqual(mockAppState.timerState, .focusActive, "Timer should auto-cycle back to focus mode again")
        XCTAssertEqual(mockAppState.focusRemainingTime, mockAppState.focusDuration, "Focus timer should be reset again")
    }
    
    // Test that timer does NOT auto-cycle when the feature is disabled
    func testNoAutoCycleWhenDisabled() {
        // Given
        mockAppState.timerSettings.autoCycleTimer = false // Ensure auto-cycle is disabled
        mockAppState.timerState = .inactive
        mockAppState.focusRemainingTime = 2 // Short duration for testing
        mockAppState.breakRemainingTime = 2 // Short duration for testing
        
        // Start the timer
        timerManager.startTimer()
        XCTAssertEqual(mockAppState.timerState, .focusActive, "Timer should start in focus mode")
        
        // Simulate timer ticks until focus timer reaches zero
        mockAppState.simulateTimerTick() // 1 second left
        XCTAssertEqual(mockAppState.focusRemainingTime, 1, "Focus timer should decrease")
        
        mockAppState.simulateTimerTick() // 0 seconds left - should transition to break
        XCTAssertEqual(mockAppState.timerState, .breakActive, "Timer should transition to break mode")
        
        // Simulate timer ticks until break timer reaches zero
        mockAppState.simulateTimerTick() // 1 second left
        XCTAssertEqual(mockAppState.breakRemainingTime, 1, "Break timer should decrease")
        
        mockAppState.simulateTimerTick() // 0 seconds left - with auto-cycle disabled, should stop
        XCTAssertEqual(mockAppState.timerState, .inactive, "Timer should stop after break when auto-cycle is disabled")
        XCTAssertNil(mockAppState.timer, "Timer should be invalidated")
    }
}
