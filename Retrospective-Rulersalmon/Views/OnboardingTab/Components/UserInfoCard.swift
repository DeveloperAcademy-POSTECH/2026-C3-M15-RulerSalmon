//
//  UserInfoCard.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 5/31/26.
//

import SwiftUI

struct UserInfoCard: View {
    @Binding var nickname: String
    @Binding var selectedJob: Job
    @Binding var selectedAgeGroup: AgeGroup
    let showsNicknameError: Bool
    let nicknameErrorTrigger: Int

    init(
        nickname: Binding<String>,
        selectedJob: Binding<Job>,
        selectedAgeGroup: Binding<AgeGroup>,
        showsNicknameError: Bool = false,
        nicknameErrorTrigger: Int = 0
    ) {
        _nickname = nickname
        _selectedJob = selectedJob
        _selectedAgeGroup = selectedAgeGroup
        self.showsNicknameError = showsNicknameError
        self.nicknameErrorTrigger = nicknameErrorTrigger
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            NicknameTextField(
                nickname: $nickname,
                title: "닉네임",
                showsError: showsNicknameError,
                errorTrigger: nicknameErrorTrigger
            )
            JobSelection(selectedJob: $selectedJob)
            AgePicker(selectedAgeGroup: $selectedAgeGroup)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 30)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
        }
    }
}

struct UserInfoCard_Previews: PreviewProvider {
    static var previews: some View {
        UserInfoCard(
            nickname: .constant("김여운"),
            selectedJob: .constant(.student),
            selectedAgeGroup: .constant(.twenties)
        )
    }
}
