//
//  OnboardingViewer.swift
//  AIReply
//
//  Created by Syed Ahmad  on 01/03/2026.
//


import SwiftUI

struct OnboardingViewer: View {
    @AppStorage("showOnboarding") var onboardingShown = false
    @State var view : Int = 0
    @State var moveToMain = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
       screenView
            .padding(.horizontal)

    }
}
extension OnboardingViewer{
    
    var screenView : some View{
        
        VStack{
           
            Text("Gsisst")
                .font(.bold(size: 24))
            
            Spacer()
            
            switch view{
                
            case 0:
                OnboardingView(content: MailCard(), title: "Smart AI Summaries", description: "Create perfect responses in seconds. Customize the tone and style to match your needs.")

            case 1:
                OnboardingView(content: MailReplyCard(), title: "Auto-Generate Replies", description: "Create perfect responses in seconds. Customize the tone and style to match your needs.")
                
            case 2:
                OnboardingView(content: SaveHoursCard(), title: "Save Minutes Daily", description: "Send the reply with just a single tap within the app.")
                
            default:
                EmptyView()
            }
            
            Spacer()
            
            tabSelectionView



            
        }
        
    }
    
}


extension OnboardingViewer{
    
    var tabSelectionView: some View{
        
        VStack(spacing: 20){
            
            HStack{
                
                ForEach(0..<3, id: \.self){ view in
                    
                    tabCell(selection: view)
                    
                }
                
            }
            
            AppButton(title: "Continue", action: {
                
                if view < 2 {
                    withAnimation {
                        view += 1
                    }
               
                } else {
                    self.moveToMain = true
//                    self.gmail.
//                   UserDefaultManager.Authenticated.send(true)
                    self.onboardingShown = true
                }
            })

            
        }
        
    }
    
    func tabCell(selection : Int) -> some View{
        
        
            RoundedRectangle(cornerRadius: 21)
            .foregroundStyle(selection == view ? colorScheme == .dark ? Color.white : Color.black : .gray)
            .frame(width: selection == view ? 30.19 : 6, height: 6)
            .onTapGesture {
                
                withAnimation {
                    self.view = selection
                }
                
            }
        
    }
    
}
#Preview {
    OnboardingViewer()
}
