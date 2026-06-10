//
//  SelectableChip.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/1/26.
//

import SwiftUI

struct SelectableChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(isSelected ? Color.blue500 : Color.gray600)
                .padding(.horizontal, 15)
                .frame(height: 36)
                .background {
                    Capsule()
                        .fill(isSelected ? Color.blue50 : Color.gray50)
                }
                .overlay {
                    Capsule()
                        .stroke(isSelected ? Color.blue500 : Color.clear, lineWidth: 2)
                }
        }
        .buttonStyle(.plain)
    }
}

struct SelectableChip_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            SelectableChip(label: "학생", isSelected: true) {}
            SelectableChip(label: "직장인", isSelected: true) {}
        }
    }
}
