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
    let showsError: Bool
    let errorTrigger: Int
    @State private var isErrorAnimating = false

    init(
        nickname: Binding<String>,
        title: String,
        showsError: Bool = false,
        errorTrigger: Int = 0
    ) {
        _nickname = nickname
        self.title = title
        self.showsError = showsError
        self.errorTrigger = errorTrigger
    }
    
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
                    .foregroundStyle(Color.gray900)
                    .tint(Color.blue500)
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
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        showsError ? Color.red : Color.gray300,
                        lineWidth: showsError ? 2 : 1
                    )
            }
            .offset(x: isErrorAnimating ? 5 : 0)
            .animation(.easeInOut(duration: 0.16), value: showsError)
            .onChange(of: errorTrigger) { _, _ in
                guard showsError else { return }
                withAnimation(.easeInOut(duration: 0.08).repeatCount(3, autoreverses: true)) {
                    isErrorAnimating = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                    isErrorAnimating = false
                }
            }
            
            Caption(caption : "멘토가 대화에서 부르는 이름으로 사용돼요.")
                
        }
        .frame(maxWidth: .infinity)
        
    }
}

struct NicknameTextField_Previews: PreviewProvider {
    static var previews: some View {
        NicknameTextField(nickname: .constant("김여운"), title : "닉네임")
    }
}


struct Caption: View {
    let caption : String
    var body: some View {
        Text(caption)
            .font(.footnote)
            .foregroundStyle(Color.gray600)
    }
}
