//
//  Title.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 5/30/26.
//

import SwiftUI

struct OnboardingTitle: View {
    let headline: String
    let subtitle: String
    
    var body: some View {
        VStack{
            Text(headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fontWeight(.bold)
                .font(.system(size: 31))
                .padding(.bottom, 16)
                .foregroundStyle(Color.gray900)
            Text(subtitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.callout)
                .foregroundStyle(Color.gray600)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal,16)
    }
}

struct OnboardingTitle_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingTitle(
            headline: "더 나은 회고를 위해 권한이 필요해요",
            subtitle: "회의 일정과 음성 기록을 더 빠르게 정리하기 위해 사용해요."
        )
    }
}
