//
//  SwipeAnimations.swift
//  AIReply
//
//  Created by Syed Ahmad  on 01/03/2026.
//


import Foundation
import SwiftUI

extension View {
    
    func swipeAnimation(startAnimation: Bool, xOffset: CGFloat = 0, yOffset: CGFloat = 0) -> some View {
        
        modifier(SwipeAnimations(startAnimation: startAnimation, xOffset: xOffset, yOffset: yOffset))
    }
}

struct SwipeAnimations: ViewModifier {
    
    private var startAnimation: Bool
    private var xOffset: CGFloat = 0
    private var yOffset: CGFloat = 0
    
    init(startAnimation: Bool,
         xOffset: CGFloat = 0,
         yOffset: CGFloat = 0) {
        
        self.startAnimation = startAnimation
        self.xOffset = xOffset
        self.yOffset = yOffset
    }
    
    func body(content: Content) -> some View {
        
        content
            .offset(x: startAnimation ? (xOffset * UIScreen.main.bounds.width / 100) : xOffset * UIScreen.main.bounds.width,
                    y: startAnimation ? (yOffset * UIScreen.main.bounds.width / 100) : yOffset * UIScreen.main.bounds.width)
            .animation(.interpolatingSpring(mass: 1.0, stiffness: 30.0, damping: 10, initialVelocity: 0), value: startAnimation)
    }
}
