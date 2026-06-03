//
//  PageIndicator.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 6/2/26.
//

import SwiftUI

struct PageIndicator: View {
    let pageCount: Int
    let selectedIndex: Int
    
    var body: some View {
        HStack(spacing: 14) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(index == selectedIndex ? Color.blue500 : Color.gray300)
                    .frame(
                        width: index == selectedIndex ? 18 : 6,
                        height: 6
                    )
                    .animation(.easeInOut(duration: 0.2), value: selectedIndex)
            }
        }
    }
}

#Preview {
    PageIndicator(pageCount: 1, selectedIndex: 0)
}
