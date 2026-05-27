//
//  AnalysisPoCViewModel.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 5/27/26.
//

import Foundation
import Combine

@MainActor
final class AnalysisPocViewModel: ObservableObject {
    @Published var transcript = MockTranscript.questionAnswerSample
    @Published var analysisResult = ""
    @Published var isAnalyzing = false
    @Published var errorMessage: String?
    private let analysisService = ReflectionAnalysisService()
    
    func analyzeTranscript() async{
        isAnalyzing = true
        errorMessage = nil
        
        do{
            let result = try await analysisService.analyze(transcript: transcript)
            analysisResult = result
        } catch{
            errorMessage = error.localizedDescription
        }
        
        isAnalyzing = false
    }
    
}
