//
//  AnimatedDigit.swift
//  Timer
//
//  Created by Bohdan Ptyts on 01.05.2025.
//
import SwiftUI

struct AnimatedDigit: View {
    let digit: Int
    
    var body: some View {
        Text("\(digit)")
            .font(.system(size: 32, weight: .bold, design: .monospaced))
            .foregroundColor(.primary)
            .frame(width: 20)
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.2), value: digit)
    }
}

struct TimeDisplay: View {
    let minutes: Int
    let seconds: Int
    
    private var minutesTens: Int {
        minutes / 10
    }
    
    private var minutesOnes: Int {
        minutes % 10
    }
    
    private var secondsTens: Int {
        seconds / 10
    }
    
    private var secondsOnes: Int {
        seconds % 10
    }
    
    var body: some View {
        HStack(spacing: 2) {
            AnimatedDigit(digit: minutesTens)
            AnimatedDigit(digit: minutesOnes)
            
            Text(":")
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
            
            AnimatedDigit(digit: secondsTens)
            AnimatedDigit(digit: secondsOnes)
        }
    }
}
