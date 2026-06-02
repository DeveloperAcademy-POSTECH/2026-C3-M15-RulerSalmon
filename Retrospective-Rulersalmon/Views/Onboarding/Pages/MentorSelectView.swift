//
//  MentorSelectView.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 5/31/26.
//

import SwiftUI

struct MentorSelectView: View {
    @Binding var selectedMentorID: Mentor.ID?
    let onNext: () -> Void
    
    var body: some View {
        ZStack {
            Color.gray50
                .ignoresSafeArea(.all)

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

                Spacer()

                AcceptButton(labelText: "멘토 선택", action: onNext)
                    .disabled(selectedMentorID == nil)
            }
        }
    }
}

struct MentorSelectView_Previews: PreviewProvider {
    static var previews: some View {
        MentorSelectView(selectedMentorID: .constant(Mentor.sampleMentors.first?.id), onNext: {})
    }
}
