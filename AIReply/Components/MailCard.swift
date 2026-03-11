//
//  MailCard.swift
//  AIReply
//
//  Created by Syed Ahmad  on 01/03/2026.
//

import SwiftUI

struct MailCard: View {
    var body: some View {
        screenView
    }
}

extension MailCard{
    
    var screenView : some View {
        
        VStack(alignment: .leading){
            
            HStack{
                
                Circle()
                    .foregroundStyle(Color(hex: "#2B7FFF"))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text("S")
                            .font(.extraBold(size: 14))
                            .foregroundStyle(Color.white)
                    }
                
                VStack(alignment: .leading, spacing: 0){
                    
                    
                    Text("Hello World this is a ")
//                        .font(.regular(size: 15))
                        .redacted(reason: .placeholder)
                        .cornerRadius(4)
                    
                    Text("Hello World")
                        .redacted(reason: .placeholder)

                  

                    
                }
                
            }
            
            
            Text("The information has already been shared with our Business Development team. They will review it and provide you with the timeline.")
                .redacted(reason: .placeholder)
            
            
            ReplyCard(title: "Project Timeline & Cost", description: "Client is requesting to share the detailed timeline and cost estimate for the proposal.", showIcon: true)
            
            
        }
        .padding()
        .background(
            
            RoundedRectangle(cornerRadius: 14)
                .foregroundStyle(Color.white)
                .shadow(radius: 25)
            
        )
        
    }
    
}

extension MailCard{
    
    
    
}

#Preview {
    MailCard()
}
