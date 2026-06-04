//
//  OnboardingFlowViewModel.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/2/26.
//

import Combine
import Foundation

@MainActor
final class OnboardingFlowViewModel: ObservableObject {
    enum Step {
        case userInfo
        case mentorSelection
        case permissions
        case reflection
    }

    @Published var step: Step = .userInfo
    @Published var nickname: String = ""
    @Published var selectedJob: Job = .student
    @Published var selectedAgeGroup: AgeGroup = .twenties
    @Published var selectedMentorID: Mentor.ID? = Mentor.sampleMentors.first?.id

    func goToMentorSelection() {
        step = .mentorSelection
    }

    func goToPermissions() {
        step = .permissions
    }

    func completeOnboarding() {
        step = .reflection
    }
}
