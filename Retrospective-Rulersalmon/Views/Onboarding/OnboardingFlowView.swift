//
//  OnboardingFlowView.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/2/26.
//

import SwiftUI

struct OnboardingFlowView: View {
    @StateObject private var viewModel = OnboardingFlowViewModel()

    var body: some View {
        Group {
            switch viewModel.step {
            case .userInfo:
                UserInfoView(
                    nickname: $viewModel.nickname,
                    selectedJob: $viewModel.selectedJob,
                    selectedAgeGroup: $viewModel.selectedAgeGroup
                ) {
                    viewModel.goToMentorSelection()
                }

            case .mentorSelection:
                MentorSelectView(selectedMentorID: $viewModel.selectedMentorID) {
                    viewModel.goToPermissions()
                }

            case .permissions:
                PermmisionView {
                    viewModel.completeOnboarding()
                }

            case .reflection:
                ContentView()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.step)
    }
}

struct OnboardingFlowView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingFlowView()
    }
}
