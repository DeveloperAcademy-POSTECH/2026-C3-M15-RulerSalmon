//
//  AcceptButton.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 5/30/26.
//

import SwiftUI

struct AcceptButtonStyle: ButtonStyle{
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.blue600)
            .frame(maxWidth:.infinity, maxHeight: 56)
            .padding(.horizontal, 16)
            .overlay{
                configuration.label
                    .foregroundStyle(Color.white)
                    .fontWeight(.bold)
            }
            
    }
}


struct AcceptButton: View {
    let labelText: String

    var body: some View {
        Button{
        }label: {
            Text(labelText)
                
                
                
        }
        .buttonStyle(AcceptButtonStyle())
  
    }
}

#Preview {
    AcceptButton(labelText: "권한 요청")
}
