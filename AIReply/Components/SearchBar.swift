//
//  SearchBar.swift
//  AIReply
//
//  Created by Syed Ahmad  on 05/03/2026.
//

import SwiftUI

struct SearchBar: View {
    @Binding var query : String
    var placeholder: String
    var body: some View {
        screenView
    }
}

extension SearchBar{
    
    var screenView: some View{
        
        HStack {
            
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField(placeholder, text: $query)
                .textInputAutocapitalization(.none)
                .disableAutocorrection(true)
            
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(.systemGray6))
        )
    }
    
}

#Preview {
    SearchBar(query: .constant(""), placeholder: "Hello")
}
