//
//  NicknameTextField.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 5/30/26.
//

import SwiftUI

struct NicknameTextField: View {
    @Binding var nickname: String
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8){
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.gray600)
            
            HStack{
                TextField("닉네임을 입력해주세요", text: $nickname)
                    .onChange(of: nickname){ _, newValue in
                        if newValue.count > 12 {
                            nickname = String(newValue.prefix(12))
                        }
                    }
                    .font(.callout)
                    .fontWeight(.bold)
                Spacer()
                
                Text("최대 12자")
                    .font(.caption)
                    .foregroundStyle(Color.gray600)
            }
            .padding(.horizontal)
            .frame(height: 48)
            .background{
                RoundedRectangle(cornerRadius : 16).fill(Color.white)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16).stroke(Color.gray300)
            }
            
            Caption(caption : "멘토가 대화에서 부르는 이름으로 사용돼요.")
                
        }
        .frame(maxWidth: .infinity)
        
    }
}

struct NicknameTextField_Previews: PreviewProvider {
    static var previews: some View {
        NicknameTextField(nickname: .constant("김여운"))
    }
}
