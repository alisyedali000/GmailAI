//
//  GmailLoader.swift
//  GClient
//
//  Created by Syed Ahmad  on 11/03/2026.
//


import SwiftUI

struct Spinner: View {
    
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .trim(from: 0.0, to: 0.75)
            .stroke(
                Color(hex: "0094FF"),
                style: StrokeStyle(lineWidth: 4, lineCap: .round)
            )
            .frame(width: 30, height: 30)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(
                .linear(duration: 1)
                .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

#Preview {
    Spinner()
}
