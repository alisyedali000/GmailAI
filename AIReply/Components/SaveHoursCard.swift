//
//  MailReplyCard 2.swift
//  AIReply
//
//  Created by Syed Ahmad  on 01/03/2026.
//


import SwiftUI

struct SaveHoursCard: View {
    var body: some View {
        screenView
    }
}

extension SaveHoursCard{
    
    var screenView : some View {
        
        VStack(spacing: 20){
            
            Image(.gClientSVG)
                .resizable()
                .frame(width: 100, height: 100)
            
            Divider()
            
            ZStack(alignment: .bottomTrailing){
                VStack{
                    
                    ReplyCard(title: "Project Timeline & Cost", description: "The information has already been shared with our designated team. They will review it and provide you with the timeline and cost estimate shortly.  Please let me know if you have any additional questions in the meantime.")
                    HStack{
                        
                        Spacer()
                        
                        HStack{
                            
                            Text("Send")
                                .font(.bold(size: 14))
                                .foregroundStyle(Color.white)
                            
                            Image(systemName: "paperplane.fill")
                                .resizable()
                                .foregroundStyle(.white)
                                .frame(width: 20, height: 20)
                                .rotationEffect(Angle(degrees: 40))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .foregroundStyle(Color.blue)
                        )
                    }
                    
                }
            }
            
        }
        .padding()
        .background(
            
            RoundedRectangle(cornerRadius: 14)
                .foregroundStyle(Color.white)
                .shadow(radius: 25)
            
        )
        
    }
    
}

extension SaveHoursCard{
    
    
    
}

#Preview {
    SaveHoursCard()
}
