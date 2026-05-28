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
            VStack(spacing: 20) {
                Spacer()

                NavigationLink {
                    ReflectionCallView()
                } label: {
                    Text("[Dev] Reflection Call Lab")
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
