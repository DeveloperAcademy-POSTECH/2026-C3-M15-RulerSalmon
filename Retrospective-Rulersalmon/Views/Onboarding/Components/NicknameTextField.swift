//
//  NicknameTextField.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 5/30/26.
//

import SwiftUI

struct NicknameTextField: View {
    @Binding var nickname: String
    
    var body: some View {
        VStack(alignment: .leading){
            Text("닉네임")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.gray600)
            
            TextField("닉네임을 입력해주세요", text: $nickname
        )
            .font(.callout)
            .fontWeight(.bold)
            .padding(.horizontal)
                      .frame(height: 54)
            .background{
                RoundedRectangle(cornerRadius : 16).fill(Color.white)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16).stroke(Color.gray300)
            }
        }
        .frame(maxWidth: .infinity)

    }
}

struct NicknameTextField_Previews: PreviewProvider {
    static var previews: some View {
        NicknameTextField(nickname: .constant("김여운"))
    }
}
