//
//  ContentView.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/21/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            OnboardingTitle(headline: "안녕하세요", subtitle: "최근 회고에서 조금 지쳐 보였어요. 오늘은 짧고 간단하게 해봐요")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
