//
//  RetrospectiveTranscriptView.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/11/26.
//

import SwiftUI

struct RetrospectiveTranscriptView: View {
    let title: String
    let transcript: String

    var body: some View {
        ZStack {
            Color.gray50
                .ignoresSafeArea(.all)

            ScrollView {
                Text(transcript)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.gray900)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppLayout.screenHorizontalPadding)
            }
        }
        .navigationTitle(title)
    }
}

struct RetrospectiveTranscriptView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RetrospectiveTranscriptView(
                title: "전사문",
                transcript: RetrospectiveReport.mock.transcript
            )
        }
    }
}
