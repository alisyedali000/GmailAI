//
//  ReplyCard.swift
//  AIReply
//
//  Created by Syed Ahmad  on 01/03/2026.
//

import SwiftUI

struct ReplyCard: View {
    var title: String
    var description: String
    var showIcon: Bool?
    var body: some View {
        screenView
    }
}
extension ReplyCard{
    
    var screenView: some View {
        
        VStack(alignment: .leading, spacing: 10){
            
            HStack{
                if showIcon ?? false {
                    Image(.magicStar)
                }
                
                HStack{
                    Text(title)
                        .font(.bold(size: 13))
                        .foregroundStyle(Color(hex: "#4968A9"))
                    Spacer()
                }
            }
            
            Text(description)
                .font(.medium(size: 13))
                .foregroundStyle(Color(hex: "#4968A9"))
            
        }
        .padding()
        .background(
            
            RoundedRectangle(cornerRadius: 14)
                .foregroundStyle(Color(hex: "#BEDBFF"))
                .opacity(0.4)
                .addStroke(radius: 14, color: Color(hex: "#BEDBFF"), lineWidth: 1)
            
        )
        
    }
    
}

#Preview {
    ReplyCard(title: "Project Timeline and Cost", description: "Client is requesting to share the detailed timeline and cost estimate for the proposalgjkdlfgjdshggkjsdfghjks.")
}
