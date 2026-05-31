//
//  UserInfoView.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 5/30/26.
//

import SwiftUI

struct UserInfoView: View {
    @State private var nickname: String = ""
    @State private var selectedJob: Job = .student
    @State private var selectedAgeGroup: AgeGroup = .twenties

    var body: some View {
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
            AcceptButton(labelText: "내 정보 저장")
    
            
        }
        .padding(.top, 40)
       
        
    }
}

#Preview {
    UserInfoView()
}
