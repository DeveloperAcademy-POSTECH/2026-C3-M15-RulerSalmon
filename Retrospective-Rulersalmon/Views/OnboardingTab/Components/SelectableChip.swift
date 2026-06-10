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
                .font(.system(size: 14))
                .fontWeight(.semibold)
                .foregroundStyle(isSelected ? Color.blue500 : Color.gray500)
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background {
                    Capsule()
                        .fill(isSelected ? Color.blue50 : Color.gray100)
                }
                .overlay {
                    Capsule()
                        .stroke(isSelected ? Color.blue100 : Color.clear, lineWidth: 1.5)
                }
        }
        .buttonStyle(.plain)
    }
}

struct SelectableChip_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            SelectableChip(label: "학생", isSelected: true) {}
            SelectableChip(label: "직장인", isSelected: false) {}
        }
    }
}
