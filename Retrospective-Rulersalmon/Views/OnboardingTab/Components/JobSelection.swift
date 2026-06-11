//
//  JobSelectionView.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/1/26.
//

import SwiftUI

struct JobSelection: View {
    @Binding var selectedJob: Job

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("직업")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.gray600)

            HStack(spacing: 10) {
                ForEach(Job.allCases) { job in
                    SelectableChip(
                        label: job.rawValue,
                        isSelected: selectedJob == job
                    ) {
                        selectedJob = job
                    }
                }
            }
            
            Caption(caption: "회고 질문과 조언을 직업 맥락에 맞게 조정해요.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct JobSelection_Previews: PreviewProvider {
    static var previews: some View {
        JobSelection(selectedJob: .constant(.student))
            .padding()
    }
}
