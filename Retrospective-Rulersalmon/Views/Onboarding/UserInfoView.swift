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
                AcceptButton(labelText: "정보 저장하기"){
                    onAccept()
                }
    
            }
            .padding(.top, 16)
            
            
        }
    }
}

#Preview {
    UserInfoView(onAccept: {})
}
