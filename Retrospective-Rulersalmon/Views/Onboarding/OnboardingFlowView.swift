//
//  OnboardingFlowView.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 6/3/26.
//

import SwiftUI

struct OnboardingFlowView: View {
    @State private var path: [OnboardingRoute] = []
    
    var body: some View {
        NavigationStack(path: $path){
            PermissionView{
                path.append(.userInfo)
            }
            .navigationDestination(for: OnboardingRoute.self){ route in
                switch route {
                case .userInfo:
                    UserInfoView {
                        path.append(.mentorSelect)
                    }
                case .mentorSelect:
                    MentorSelectView()
                }
            }
        }
    }
}

#Preview {
    OnboardingFlowView()
}
