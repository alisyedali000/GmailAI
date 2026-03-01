//
//  MailCard 2.swift
//  AIReply
//
//  Created by Syed Ahmad  on 01/03/2026.
//


import SwiftUI

struct MailReplyCard: View {
    var body: some View {
        screenView
    }
}

extension MailReplyCard{
    
    var screenView : some View {
        
        VStack{
            
            HStack{
                
                HStack{
                    
                    Image(.blueFlash)
                    
                    Text("Hello World")
//                        .font(.regular(size: 15))
                        .redacted(reason: .placeholder)
                        .cornerRadius(4)
                    
             
     
                }
                
                Spacer()
                
                Circle()
                    .foregroundStyle(Color(hex: "#2B7FFF"))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text("S")
                            .font(.extraBold(size: 14))
                            .foregroundStyle(Color.white)
                    }
                
            }
            
            
            Text("The information has already been shared with our Business Development")
                .redacted(reason: .placeholder)
                .padding()
                .background(
                    
                    RoundedRectangle(cornerRadius: 14)
                        .foregroundStyle(Color.gray.opacity(0.1))
                    
                )
            
            
            ReplyCard(title: "RE: Project Timeline & Cost", description: "The information has already been shared with the designated team. They will review it and provide you with the timeline and cost estimate shortly. \n\nPlease let me know if you have any additional questions in the meantime.")
            
            
        }
        .padding()
        .background(
            
            RoundedRectangle(cornerRadius: 14)
                .foregroundStyle(Color.white)
                .shadow(radius: 25)
            
        )
        
    }
    
}

extension MailReplyCard{
    
    
    
}

#Preview {
    MailReplyCard()
}
