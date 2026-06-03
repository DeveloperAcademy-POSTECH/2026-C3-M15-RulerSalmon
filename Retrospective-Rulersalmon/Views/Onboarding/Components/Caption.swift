//
//  Caption.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 6/2/26.
//

import SwiftUI

struct Caption: View {
    let caption : String
    var body: some View {
        Text(caption)
            .font(.footnote)
            .foregroundStyle(Color.gray600)
    }
}

#Preview {
    Caption(caption : "멘토가 대화에서 부르는 이름으로 사용돼요.")
}
