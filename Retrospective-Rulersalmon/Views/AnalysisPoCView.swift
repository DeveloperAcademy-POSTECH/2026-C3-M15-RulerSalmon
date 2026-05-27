//
//  FoundationAnalysisPoCView.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 5/27/26.
//

import SwiftUI

struct AnalysisPoCView: View {
    @StateObject private var viewModel = AnalysisPocViewModel()
    
    var body: some View {
        
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Foundation Model 분석 PoC")
                    .font(.title2)
                    .bold()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("목업 전사문")
                        .font(.headline)
                    
                    TextEditor(text: $viewModel.transcript)
                        .frame(minHeight: 220)
                        .padding(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.4))
                        )
                }
                
                Button {
                    Task {
                        await viewModel.analyzeTranscript()
                    }
                } label: {
                    Text(viewModel.isAnalyzing ? "분석 중..." : "분석하기")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isAnalyzing ? Color.gray : Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(viewModel.isAnalyzing)
            
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    
                    Text("분석 결과")
                        .font(.headline)
                    
                    if viewModel.analysisResult.isEmpty {
                        Text("아직 분석 결과가 없습니다.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Text(viewModel.analysisResult)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                    }
                }
                Spacer()
            }
            .padding()
        }
    }
}



#Preview {
    AnalysisPoCView()
}
