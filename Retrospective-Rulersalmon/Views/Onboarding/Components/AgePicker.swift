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
        VStack(alignment: .leading, spacing: 14) {
            Text("연령대")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.gray600)

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

                    Image(systemName: "chevron.down")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.gray600)
                }
                .padding(.horizontal, 28)
                .frame(height: 54)
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AgePicker_Previews: PreviewProvider {
    static var previews: some View {
        AgePicker(selectedAgeGroup: .constant(.twenties))
            .padding()
    }
}
