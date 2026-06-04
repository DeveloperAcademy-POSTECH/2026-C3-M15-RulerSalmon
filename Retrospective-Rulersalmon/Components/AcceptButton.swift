//
//  AcceptButton.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 5/30/26.
//

import SwiftUI

struct AcceptButtonStyle: ButtonStyle{
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        RoundedRectangle(cornerRadius: 50)
            .fill(Color.blue600)
            .frame(maxWidth:.infinity, maxHeight: 60)
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
    let action: () -> Void

    var body: some View {
        Button{
            action()
        }label: {
            Text(labelText)
        }
        .buttonStyle(AcceptButtonStyle())
  
    }
}

struct AcceptButton_Previews: PreviewProvider {
    static var previews: some View {
        AcceptButton(labelText: "권한 요청", action: {})
    }
}
