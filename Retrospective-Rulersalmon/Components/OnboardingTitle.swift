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
        VStack(alignment: .leading, spacing: 16){
            Text(headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fontWeight(.bold)
                .font(.system(size: 31))
                .foregroundStyle(Color.gray900)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.callout)
                .foregroundStyle(Color.gray600)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppLayout.screenHorizontalPadding)
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
