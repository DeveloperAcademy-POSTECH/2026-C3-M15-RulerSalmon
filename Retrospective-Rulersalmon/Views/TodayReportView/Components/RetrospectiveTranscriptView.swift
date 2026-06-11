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
    let messages: [ChatMessage]

    private let bubbleShadowColor = Color(
        red: 23.0 / 255.0,
        green: 33.0 / 255.0,
        blue: 29.0 / 255.0
    ).opacity(0.08)

    init(
        title: String,
        transcript: String,
        messages: [ChatMessage] = []
    ) {
        self.title = title
        self.transcript = transcript
        self.messages = messages
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea(.all)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        Spacer(minLength: 0)

                        ForEach(displayMessages) { message in
                            ChatBubbleView(
                                message: message,
                                bubbleShadowColor: bubbleShadowColor
                            )
                            .id(message.id.uuidString)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppLayout.screenHorizontalPadding)
                    .padding(.top, 18)
                    .padding(.bottom, 32)
                }
                .onAppear {
                    guard let lastMessage = displayMessages.last else { return }
                    proxy.scrollTo(lastMessage.id.uuidString, anchor: .bottom)
                }
            }
        }
        .navigationTitle(title)
    }

    private var displayMessages: [ChatMessage] {
        let visibleMessages = messages.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        if !visibleMessages.isEmpty {
            return visibleMessages
        }

        let fallbackTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !fallbackTranscript.isEmpty else { return [] }
        return [ChatMessage(role: .user, text: fallbackTranscript)]
    }
}

struct RetrospectiveTranscriptView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RetrospectiveTranscriptView(
                title: "대화 내역",
                transcript: RetrospectiveReport.mock.transcript,
                messages: RetrospectiveReport.mock.transcriptMessages
            )
        }
    }
}
