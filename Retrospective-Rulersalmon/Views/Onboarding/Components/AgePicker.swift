//
//  AgePickerView.swift
//  Retrospective-Rulersalmon
//
//  Created by Codex on 6/1/26.
//

import SwiftUI

struct AgePicker: View {
    @Binding var selectedAgeGroup: AgeGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("나이")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.gray600)
            VStack(alignment: .leading, spacing: 8){
                Menu {
                    ForEach(AgeGroup.allCases) { ageGroup in
                        Button(ageGroup.rawValue) {
                            selectedAgeGroup = ageGroup
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedAgeGroup.rawValue)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.gray900)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 28)
                    .frame(height: 48)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray300)
                    }
                }
                .buttonStyle(.plain)
                
                Caption(caption: "회고 질문과 조언을 나이 맥락에 맞게 조정해요.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct AgePicker_Previews: PreviewProvider {
    static var previews: some View {
        AgePicker(selectedAgeGroup: .constant(.twenties))
            .padding()
    }
}
