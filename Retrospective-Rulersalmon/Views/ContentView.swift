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
            ReflectionCallView()
                .padding()
        }
    }
}

#Preview {
    ContentView()
}
