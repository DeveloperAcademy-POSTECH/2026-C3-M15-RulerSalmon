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
    @Published var appleIntelligencePermissionGranted: Bool = false
    @Published var validationMessage: String?

    private let dataStore: AppDataStore

    init(dataStore: AppDataStore? = nil) {
        self.dataStore = dataStore ?? .shared
        loadStoredProfile()
    }

    var canProceedFromUserInfo: Bool {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2 && trimmed.count <= 12
    }

    var canProceedFromMentorSelection: Bool {
        selectedMentorID != nil
    }

    func goToMentorSelection() {
        guard canProceedFromUserInfo else {
            validationMessage = "닉네임은 2자 이상 12자 이하로 입력해 주세요."
            return
        }

        validationMessage = nil
        persistProfile(onboardingCompleted: false)
        step = .mentorSelection
    }

    func goToPermissions() {
        guard canProceedFromMentorSelection else {
            validationMessage = "멘토를 선택해 주세요."
            return
        }

        validationMessage = nil
        persistProfile(onboardingCompleted: false)
        step = .permissions
    }

    func completeOnboarding() {
        appleIntelligencePermissionGranted = true
        validationMessage = nil
        persistProfile(onboardingCompleted: true)
        step = .reflection
    }

    private func loadStoredProfile() {
        guard let profile = dataStore.loadCurrentProfile() else { return }

        nickname = profile.nickname
        selectedJob = Job(rawValue: profile.jobRawValue) ?? .student
        selectedAgeGroup = AgeGroup(rawValue: profile.ageGroupRawValue) ?? .twenties
        selectedMentorID = profile.mentorID ?? Mentor.sampleMentors.first?.id
        appleIntelligencePermissionGranted = profile.appleIntelligencePermissionGranted

        if profile.onboardingCompleted {
            step = .reflection
        }
    }

    private func persistProfile(onboardingCompleted: Bool) {
        let mentor = Mentor.sampleMentors.first(where: { $0.id == selectedMentorID })
        dataStore.saveProfile(
            nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
            job: selectedJob,
            ageGroup: selectedAgeGroup,
            mentor: mentor,
            appleIntelligencePermissionGranted: appleIntelligencePermissionGranted,
            onboardingCompleted: onboardingCompleted
        )
    }
}
