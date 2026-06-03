//
//  MentorSelectView.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 5/31/26.
//

import SwiftUI

struct MentorSelectView: View {
    @State private var selectedIndex: Int = 0
    
    private let mentors = Mentor.sampleMentors
    
    var body: some View {
        ZStack {
            Color.gray50
                .ignoresSafeArea(.all)
            
            VStack(spacing : 0){
                OnboardingTitle(headline: "회고 멘토를 선택해 주세요", subtitle: "멘토는 나중에라도\n제한 없이 변경할 수 있어요.")
                    .padding(.bottom,10)
                    
                TabView(selection: $selectedIndex) {
                    ForEach(mentors.indices, id: \.self) { index in
                        MentorCard(
                            mentor: mentors[index],
                            isSelected: selectedIndex == index,
                            onTap: {
                                selectedIndex = index
                            }
                        )
                        .tag(index)
                        .padding(.horizontal, 51)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                
                
                PageIndicator(
                    pageCount: mentors.count,
                    selectedIndex: selectedIndex
                )
                .padding(.top, 8)
                .padding(.bottom, 28)
                
                Spacer()
                
                AcceptButton(labelText:  "멘토 선택하기", action:{})
                
            }
            .padding(.top,16)
        }
    }
}


#Preview {
    MentorSelectView()
}
