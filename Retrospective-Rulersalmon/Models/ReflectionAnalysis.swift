//
//  ReflectionAnalysis.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 5/27/26.
//

//Foundation model이 뽑아줘야되는 분석 결과 형태
import Foundation

struct ReflectionAnalysis{
    let summary: String
    let keywords: [String]
    let liked: String
    let lacked: String
    let longedFor: String
}
