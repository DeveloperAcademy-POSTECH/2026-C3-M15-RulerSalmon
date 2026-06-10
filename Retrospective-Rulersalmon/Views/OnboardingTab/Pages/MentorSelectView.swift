//
//  MentorSelectView.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 5/31/26.
//

import SwiftUI

struct MentorSelectView: View {
    @Binding var selectedMentorID: Mentor.ID?
    let validationMessage: String?
    let onNext: () -> Void
    
    private let mentors = Mentor.sampleMentors
    
    private var selectedMentorBinding: Binding<Mentor.ID> {
        Binding(
            get: { selectedMentorID ?? mentors[0].id },
            set: { selectedMentorID = $0 }
        )
    }
    
    private var selectedIndex: Int {
        mentors.firstIndex { $0.id == selectedMentorID } ?? 0
    }
    
    var body: some View {
        ZStack {
            Color.white

            VStack{
                OnboardingTitle(headline: "회고 멘토를 선택해 주세요", subtitle: "멘토는 나중에라도 제한 없이 변경할 수 있어요.")
                
                TabView(selection: selectedMentorBinding) {
                    ForEach(mentors) { mentor in
                        MentorCard(
                            mentor: mentor,
                            isSelected: selectedMentorID == mentor.id
                        )
                        .tag(mentor.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
//                .frame(height: 500)
                
                PageIndicator(pageCount: mentors.count, selectedIndex: selectedIndex)

                if let validationMessage {
                    Text(validationMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.red)
                }
                
                Spacer()

                AcceptButton(labelText: "멘토 선택하기", action: onNext)
                    .disabled(selectedMentorID == nil)
            }
            .padding(.top,40)
        }
        .onAppear {
            selectedMentorID = selectedMentorID ?? mentors.first?.id
        }
    }
}

//커스텀 PageIndicator
struct PageIndicator: View {
    let pageCount: Int
    let selectedIndex: Int
    
    var body: some View {
        HStack(spacing: 14) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(index == selectedIndex ? Color.blue500 : Color.gray300)
                    .frame(
                        width: index == selectedIndex ? 18 : 6,
                        height: 6
                    )
                    .animation(.easeInOut(duration: 0.2), value: selectedIndex)
            }
        }
        .padding(16)
    }
}


struct MentorSelectView_Previews: PreviewProvider {
    static var previews: some View {
        MentorSelectView(selectedMentorID: .constant(Mentor.sampleMentors.first?.id), validationMessage: nil, onNext: {})
    }
}
