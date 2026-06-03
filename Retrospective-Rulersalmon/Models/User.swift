//
//  User.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 5/30/26.
//

import Foundation

enum Job: String, CaseIterable, Identifiable {
    case student = "학생"
    case freelancer = "프리랜서"
    case employee = "직장인"
    case other = "기타"

    var id: String { rawValue }
}

enum AgeGroup: String, CaseIterable, Identifiable {
    case teens = "10대"
    case twenties = "20대"
    case thirties = "30대"
    case forties = "40대"
    case fiftiesAndAbove = "50대 이상"

    var id: String { rawValue }
}

class User {
    let nickname: String
    let job: Job
    let ageGroup: AgeGroup

    init(nickname: String, job: Job, ageGroup: AgeGroup) {
        self.nickname = nickname
        self.job = job
        self.ageGroup = ageGroup
    }
}
