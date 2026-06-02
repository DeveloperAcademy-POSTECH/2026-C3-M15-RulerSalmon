import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TTSViewModel()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Picker("Mode", selection: $viewModel.mode) {
                    Text("Remote").tag(TTSMode.remote)
                    Text("Local ONNX").tag(TTSMode.local)
                }
                .pickerStyle(.segmented)

                TextField("읽고 싶은 문장을 입력해", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)

                Button(viewModel.isSynthesizing ? "합성 중..." : "음성 생성") {
                    viewModel.synthesize()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isSynthesizing || viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if let statusMessage = viewModel.statusMessage {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("MeloTTS Demo")
        }
    }
}
