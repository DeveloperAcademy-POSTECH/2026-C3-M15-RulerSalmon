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
    let onNext: () -> Void
    
    let onAccept: () -> Void
    
    var body: some View {
        ZStack {
            Color.gray50
                .ignoresSafeArea(.all)
            VStack {
                OnboardingTitle(
                    headline: "정보를 입력해 주세요",
                    subtitle: "입력해 주신 정보는\n추천 질문 개인화에만 사용돼요."
                )
                .padding(.bottom, 24)
                
                UserInfoCard(
                    nickname: $nickname,
                    selectedJob: $selectedJob,
                    selectedAgeGroup: $selectedAgeGroup
                )
                
                Spacer()
                AcceptButton(labelText: "내 정보 저장", action: onNext)
    
            }
            .padding(.top, 16)
            
            
        }
    }
}

struct UserInfoView_Previews: PreviewProvider {
    static var previews: some View {
        UserInfoView(
            nickname: .constant(""),
            selectedJob: .constant(.student),
            selectedAgeGroup: .constant(.twenties),
            onNext: {}
        )
    }
}
