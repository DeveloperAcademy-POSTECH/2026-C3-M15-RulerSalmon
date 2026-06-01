//
//  MentorSelectView.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 5/31/26.
//

import SwiftUI

struct MentorSelectView: View {
    @State private var selectedMentorID: Mentor.ID? = Mentor.sampleMentors.first?.id
    
    var body: some View {
        VStack{
            OnboardingTitle(headline: "나의 회고를 도와줄\n멘토를 선택해 주세요", subtitle: "멘토는 나중에 제한 없이 변경할 수 있어요.")
            
            TabView(selection: $selectedMentorID) {
                ForEach(Mentor.sampleMentors) { mentor in
                    MentorCard(
                        mentor: mentor,
                        isSelected: selectedMentorID == mentor.id,
                        onTap: {
                            selectedMentorID = mentor.id
                        }
                    )
                    .tag(Optional(mentor.id))
                    .padding(.horizontal, 24)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 520)
        }
        
        
    }
}

#Preview {
    MentorSelectView()
}
