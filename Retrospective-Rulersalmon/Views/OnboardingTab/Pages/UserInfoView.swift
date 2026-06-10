//
//  UserInfoView.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 5/30/26.
//

import SwiftUI

struct UserInfoView: View {
    @Binding var nickname: String
    @Binding var selectedJob: Job
    @Binding var selectedAgeGroup: AgeGroup
    let validationMessage: String?
    let isNextEnabled: Bool
    let onNext: () -> Void
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea(.all)

            VStack {
                OnboardingTitle(
                    headline: "정보를 입력해 주세요",
                    subtitle: "입력해 주신 정보는\n추천 질문 개인화에만 사용해요."
                ).padding(.bottom, 20)
                
                UserInfoCard(
                    nickname: $nickname,
                    selectedJob: $selectedJob,
                    selectedAgeGroup: $selectedAgeGroup
                )

                if let validationMessage {
                    Text(validationMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.red)
                        .padding(.top, 12)
                }
                
                Spacer()
                AcceptButton(labelText: "정보 저장하기", action: onNext)
                    .disabled(!isNextEnabled)
    
            }
            .padding(.top, 40)
            
            
        }
    }
}

struct UserInfoView_Previews: PreviewProvider {
    static var previews: some View {
        UserInfoView(
            nickname: .constant(""),
            selectedJob: .constant(.student),
            selectedAgeGroup: .constant(.twenties),
            validationMessage: nil,
            isNextEnabled: false,
            onNext: {}
        )
    }
}
