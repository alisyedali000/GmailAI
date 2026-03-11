//
//  OnboardingView.swift
//  AIReply
//
//  Created by Syed Ahmad  on 01/03/2026.
//


import SwiftUI

struct OnboardingView<Content: View>: View {
    @State private var animate: Bool = false
    var content: Content
    var title: String
    var description: String
    var body: some View {
        screenView
            .onAppear(){
                
                viewDidLoad()
                
            }
    }
}

extension OnboardingView{
    
    var screenView: some View {
        
        VStack(spacing: 20){
            
            content
                .swipeAnimation(startAnimation: animate, xOffset: 1)
            
            Text(title)
                .font(.bold(size: 16))
                .padding(.vertical)
                .opacity(animate ? 1 : 0.1)
            
            Text(description)
                .font(.regular(size: 12))
                .foregroundStyle(Color.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)
                .opacity(animate ? 1 : 0.1)
            
        }
        
    }
    
}

extension OnboardingView{
    
    func viewDidLoad() {
        debugPrint("pageOne")
        self.animate = false

        withAnimation(.easeOut(duration: 2)) {
            self.animate = true
        }
    }
    
}

#Preview {
    OnboardingView(content: MailCard(), title: "Hello", description: "Hello This is some random description")
}
