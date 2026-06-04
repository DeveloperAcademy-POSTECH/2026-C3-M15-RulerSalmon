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

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            NicknameTextField(nickname: $nickname, title: "닉네임")
            JobSelection(selectedJob: $selectedJob)
            AgePicker(selectedAgeGroup: $selectedAgeGroup)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 30)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray300)
        }
        .padding(.horizontal, 16)
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
