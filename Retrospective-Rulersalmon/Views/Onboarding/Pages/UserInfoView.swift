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
    
    var body: some View {
        ZStack {
            Color.gray50
                .ignoresSafeArea(.all)
            VStack {
                OnboardingTitle(
                    headline: "더 나은 회고를 위해\n몇 가지만 알려주세요",
                    subtitle: "답변은 추천 질문을\n개인화하는 데만 사용돼요."
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
            onNext: {}
        )
    }
}
