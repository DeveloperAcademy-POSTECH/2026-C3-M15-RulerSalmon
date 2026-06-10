//
//  ProfileEditorViewModel.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/10/26.
//

import Foundation
import Combine

@MainActor
final class ProfileEditorViewModel: ObservableObject {
    @Published var nickname: String = ""
    @Published var selectedJob: Job = .student
    @Published var selectedAgeGroup: AgeGroup = .twenties
    @Published var selectedMentorID: Mentor.ID? = Mentor.sampleMentors.first?.id
    @Published var validationMessage: String?

    private let dataStore: AppDataStore
    private var appleIntelligencePermissionGranted = false
    private var onboardingCompleted = false

    init(dataStore: AppDataStore? = nil) {
        self.dataStore = dataStore ?? .shared
        loadProfile()
    }

    var canSaveUserInfo: Bool {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2 && trimmed.count <= 12
    }

    var canSaveMentor: Bool {
        selectedMentorID != nil
    }

    func saveUserInfo() -> Bool {
        guard canSaveUserInfo else {
            validationMessage = "닉네임은 2자 이상 12자 이하로 입력해 주세요."
            return false
        }

        validationMessage = nil
        persistProfile()
        return true
    }

    func saveMentor() -> Bool {
        guard canSaveMentor else {
            validationMessage = "멘토를 선택해 주세요."
            return false
        }

        validationMessage = nil
        persistProfile()
        return true
    }

    private func loadProfile() {
        guard let profile = dataStore.loadCurrentProfile() else { return }

        nickname = profile.nickname
        selectedJob = Job(rawValue: profile.jobRawValue) ?? .student
        selectedAgeGroup = AgeGroup(rawValue: profile.ageGroupRawValue) ?? .twenties
        selectedMentorID = Mentor.resolvedID(
            storedID: profile.mentorID,
            storedName: profile.mentorName
        )
        appleIntelligencePermissionGranted = profile.appleIntelligencePermissionGranted
        onboardingCompleted = profile.onboardingCompleted
    }

    private func persistProfile() {
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
