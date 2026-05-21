//
//  ContentView.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/21/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack() {
                Spacer()

                NavigationLink {
                    AssistantChatView()
                } label: {
                    Text("[Dev] STT and Foundation Model")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                Spacer()
            }
            .padding()
        }
    }
}
