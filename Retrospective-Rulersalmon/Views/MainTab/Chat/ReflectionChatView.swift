//
//  ReflectionChatView.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/2/26.
//

import SwiftUI

struct ReflectionChatView: View {
    @StateObject private var viewModel: ReflectionChatViewModel
    @FocusState private var isInputFocused: Bool
    @State private var isShowingResult = false
    @State private var isShowingFinishAlert = false
    @State private var resultMessages: [ChatMessage] = []
    @Environment(\.dismiss) private var dismiss
    private let onExitToMain: (() -> Void)?

    private let bubbleShadowColor = Color(
        red: 23.0 / 255.0,
        green: 33.0 / 255.0,
        blue: 29.0 / 255.0
    ).opacity(0.08)

    @MainActor
    init() {
        _viewModel = StateObject(wrappedValue: ReflectionChatViewModel())
        onExitToMain = nil
    }

    init(viewModel: ReflectionChatViewModel, onExitToMain: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onExitToMain = onExitToMain
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 18) {
                            Spacer(minLength: 0)

                            ForEach(viewModel.messages) { message in
                                ChatBubbleView(
                                    message: message,
                                    bubbleShadowColor: bubbleShadowColor
                                )
                                .id(message.id.uuidString)
                            }

                            if viewModel.isResponding {
                                ProcessingBubbleView(bubbleShadowColor: bubbleShadowColor)
                                    .id("responding-anchor")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppLayout.screenHorizontalPadding)
                        .padding(.bottom, 0)
                    }
                    .onAppear {
                        scrollToBottom(using: proxy)
                    }
                    .onChange(of: viewModel.scrollTargetID) { _, newValue in
                        guard newValue != nil else { return }
                        scrollToBottom(using: proxy)
                    }
                }

                ChatComposerView(
                    text: $viewModel.inputText,
                    isInputFocused: $isInputFocused,
                    isResponding: viewModel.isResponding,
                    onSend: viewModel.sendMessage
                )
            }

            VStack {
                Spacer()

                HStack {
                    Spacer()

                    GlassEffectContainer {
                        Button {
                            isShowingFinishAlert = true
                        } label: {
                            Image(systemName: "power")
                                .font(.system(size: 20, weight: .regular))
                                .frame(width: 24, height: 32)
                        }
                        .buttonStyle(.glass)
                    }
                    .disabled(viewModel.isResponding)
                    .opacity(viewModel.isResponding ? 0.5 : 1)
                    .padding(.trailing, AppLayout.screenHorizontalPadding)
                    .padding(.bottom, 84)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isInputFocused = false
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $isShowingResult) {
            RetrospectiveAnalysisView(
                messages: resultMessages,
                onExitToMain: exitToMain
            )
        }
        .task {
            viewModel.prepareFoundationModelIfNeeded()
        }
        .alert("안내", isPresented: Binding(
            get: { viewModel.alertMessage != nil },
            set: { if !$0 { viewModel.alertMessage = nil } }
        )) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
        .alert("오늘의 회고를 종료할까요?", isPresented: $isShowingFinishAlert) {
            Button("취소", role: .cancel) { }
            Button("종료하기") {
                finishReflection()
            }
        } message: {
            Text("종료하면 오늘의 회고 세션이 자동으로 생성돼요.")
        }
    }

    private func finishReflection() {
        isInputFocused = false
        guard let finishedMessages = viewModel.finishReflection() else { return }
        resultMessages = finishedMessages
        isShowingResult = true
    }

    private func exitToMain() {
        isShowingResult = false
        if let onExitToMain {
            onExitToMain()
        } else {
            dismiss()
        }
    }

    private func scrollToBottom(using proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            if viewModel.isResponding {
                proxy.scrollTo("responding-anchor", anchor: .bottom)
            } else if let target = viewModel.scrollTargetID {
                proxy.scrollTo(target, anchor: .bottom)
            }
        }
    }
}

struct ReflectionChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ReflectionChatView()
        }
    }
}
