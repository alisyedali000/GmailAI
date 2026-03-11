//
//  AppButton.swift
//  AIReply
//
//  Created by Syed Ahmad  on 01/03/2026.
//


import SwiftUI

struct AppButton: View {
    @Environment(\.colorScheme) var colorScheme
    var color : Color?
    var title : String
    var action: () -> Void
    var body: some View {
       screenView
    }
}

extension AppButton{
    
    var screenView: some View {

            Button{
                self.action()
            }label:{
               
                RoundedRectangle(cornerRadius: 16)
                    .foregroundStyle(color ?? ( colorScheme == .dark ? .white : Color.appPrimary))
                    .frame(height: 56)
                    .overlay {
                        Text(title)
                            .font(.semiBold(size: 16))
                            .foregroundStyle(colorScheme == .dark ? .black : .white)
                    }
                
            }
            .padding(.vertical)
        
    }
    
}

#Preview {
    AppButton(title: "Next", action: {
        
    })
}

