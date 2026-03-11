//
//  SignInView.swift
//  AIReply
//
//  Created by Syed Ahmad  on 07/02/2026.
//


import SwiftUI

struct SignInView: View {
    @ObservedObject var gmail: GmailViewModel

    var body: some View {
        screenView
            .padding(.horizontal)
    }
}

extension SignInView{
    
    var screenView: some View {
        
        VStack(spacing: 24) {
            
            Spacer()
            
            Image(.gClientLogoOnly)
                .resizable()
                .frame(width: 200, height: 200)

            Spacer()
            
            socialLoginButton
                .padding(.bottom)
        }
        
    }
    
    var socialLoginButton: some View {
        
        Button{
            Task {
                await gmail.signIn()
            }
        }label:{
            RoundedRectangle(cornerRadius: 8)
                .foregroundStyle(Color.white)
                .frame(height: 48)
                .overlay{
                    HStack{
                        
                        Image(.google)
                            .resizable()
                            .frame(width: 20, height: 20)
                        
                        Text("Continue with Google")
                            .font(.semiBold(size: 14))
                            .foregroundStyle(Color.black)
                        
                    }
                }
                .addStroke(radius: 8, color: .black, lineWidth: 1.5)
        }
        
    }
    
    
}

#Preview {
    SignInView(gmail: GmailViewModel.makeDefault())
}
