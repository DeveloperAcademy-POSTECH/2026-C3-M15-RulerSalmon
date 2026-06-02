//
//  PermmisionView.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 5/30/26.
//

import SwiftUI

struct PermmisionView: View {
    let onNext: () -> Void
    
    var body: some View {
        ZStack {
            Color.gray50
                .ignoresSafeArea(.all)
            
            VStack {
                OnboardingTitle(
                    headline: "더 나은 회고를 위해 권한이 필요해요",
                    subtitle: "회의 일정과 음성 기록을\n더 빠르게 정리하기 위해 사용해요."
                )
                    .padding(.bottom, 24)
                
                PermissionRow(
                    permissionTitle: "마이크",
                    permissionDescription: "회의 내용을 요약하고 다음 할 일을 정리해요.",
                    systemImageName: "mic.fill"
                )
                
                PermissionRow(
                    permissionTitle: "음성 인식",
                    permissionDescription: "회고 내용을 텍스트로 바꾸기 위해 음성 인식 권한을 사용합니다.",
                    systemImageName: "waveform"
                )
                
                Spacer()
                
                AcceptButton(labelText: "권한 요청", action: onNext)
            }
            .padding(.top, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PermmisionView_Previews: PreviewProvider {
    static var previews: some View {
        PermmisionView(onNext: {})
    }
}
