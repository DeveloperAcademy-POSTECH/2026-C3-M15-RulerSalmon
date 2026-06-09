import CoreML
import Foundation

struct TokenizedInput {
    let inputIds: MLMultiArray
    let attentionMask: MLMultiArray
    let tokenTypeIds: MLMultiArray
}

struct HowRUTokenizer {
    private static let vocabSubdirectories = [
        "MLModels/SentimentAnalysis",
        "Resources/MLModels/SentimentAnalysis"
    ]

    private let vocab: [String: Int32]
    private let unknownToken = "[UNK]"
    private let clsToken = "[CLS]"
    private let sepToken = "[SEP]"
    private let padToken = "[PAD]"
    private let maxInputCharactersPerWord = 100

    var isReady: Bool {
        !vocab.isEmpty
    }

    init(vocabResourceName: String = "vocab") {
        vocab = Self.loadVocab(resourceName: vocabResourceName)
    }

    func encode(_ text: String, maxLength: Int) -> TokenizedInput? {
        guard maxLength >= 2, !vocab.isEmpty else { return nil }

        var tokens = [clsToken]
        for token in basicTokenize(text) {
            tokens.append(contentsOf: wordPieceTokenize(token))
        }
        tokens.append(sepToken)

        if tokens.count > maxLength {
            tokens = Array(tokens.prefix(maxLength))
            tokens[maxLength - 1] = sepToken
        }

        var inputIds = tokens.map { vocab[$0] ?? vocab[unknownToken] ?? 1 }
        var attentionMask = Array(repeating: Int32(1), count: inputIds.count)
        var tokenTypeIds = Array(repeating: Int32(0), count: inputIds.count)

        let padId = vocab[padToken] ?? 0
        while inputIds.count < maxLength {
            inputIds.append(padId)
            attentionMask.append(0)
            tokenTypeIds.append(0)
        }

        guard
            let inputIdsArray = makeMultiArray(inputIds),
            let attentionMaskArray = makeMultiArray(attentionMask),
            let tokenTypeIdsArray = makeMultiArray(tokenTypeIds)
        else {
            return nil
        }

        return TokenizedInput(
            inputIds: inputIdsArray,
            attentionMask: attentionMaskArray,
            tokenTypeIds: tokenTypeIdsArray
        )
    }

    private func basicTokenize(_ text: String) -> [String] {
        var tokens: [String] = []
        var current = ""

        for scalar in text.unicodeScalars {
            if CharacterSet.whitespacesAndNewlines.contains(scalar) {
                appendCurrentToken(&current, to: &tokens)
            } else if isControl(scalar) {
                continue
            } else if isPunctuation(scalar) || isCJKCharacter(scalar) {
                appendCurrentToken(&current, to: &tokens)
                tokens.append(String(scalar))
            } else {
                current.unicodeScalars.append(scalar)
            }
        }

        appendCurrentToken(&current, to: &tokens)
        return tokens
    }

    private func appendCurrentToken(_ current: inout String, to tokens: inout [String]) {
        if !current.isEmpty {
            tokens.append(current)
            current = ""
        }
    }

    private func wordPieceTokenize(_ token: String) -> [String] {
        let characters = Array(token)
        guard !characters.isEmpty else { return [] }
        guard characters.count <= maxInputCharactersPerWord else { return [unknownToken] }

        var subTokens: [String] = []
        var start = 0

        while start < characters.count {
            var end = characters.count
            var currentSubstring: String?

            while start < end {
                var piece = String(characters[start..<end])
                if start > 0 {
                    piece = "##" + piece
                }

                if vocab[piece] != nil {
                    currentSubstring = piece
                    break
                }

                end -= 1
            }

            guard let currentSubstring else {
                return [unknownToken]
            }

            subTokens.append(currentSubstring)
            start = end
        }

        return subTokens
    }

    private func makeMultiArray(_ values: [Int32]) -> MLMultiArray? {
        guard let array = try? MLMultiArray(
            shape: [1, NSNumber(value: values.count)],
            dataType: .int32
        ) else {
            return nil
        }

        for index in values.indices {
            array[[NSNumber(value: 0), NSNumber(value: index)]] = NSNumber(value: values[index])
        }

        return array
    }

    private static func loadVocab(resourceName: String) -> [String: Int32] {
        guard let url = vocabURL(resourceName: resourceName),
              let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return [:]
        }

        var vocab: [String: Int32] = [:]
        for (index, token) in contents.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let cleanedToken = String(token).trimmingCharacters(in: .newlines)
            vocab[cleanedToken] = Int32(index)
        }

        return vocab
    }

    private static func vocabURL(resourceName: String) -> URL? {
        for subdirectory in vocabSubdirectories {
            if let url = Bundle.main.url(
                forResource: resourceName,
                withExtension: "txt",
                subdirectory: subdirectory
            ) {
                return url
            }
        }

        return Bundle.main.url(forResource: resourceName, withExtension: "txt")
    }

    private func isControl(_ scalar: UnicodeScalar) -> Bool {
        if scalar.value == 0x0009 || scalar.value == 0x000A || scalar.value == 0x000D {
            return false
        }

        return CharacterSet.controlCharacters.contains(scalar)
    }

    private func isPunctuation(_ scalar: UnicodeScalar) -> Bool {
        let value = scalar.value
        if (33...47).contains(value) ||
            (58...64).contains(value) ||
            (91...96).contains(value) ||
            (123...126).contains(value) {
            return true
        }

        return CharacterSet.punctuationCharacters.contains(scalar)
    }

    private func isCJKCharacter(_ scalar: UnicodeScalar) -> Bool {
        let value = scalar.value
        return (0x4E00...0x9FFF).contains(value) ||
            (0x3400...0x4DBF).contains(value) ||
            (0x20000...0x2A6DF).contains(value) ||
            (0x2A700...0x2B73F).contains(value) ||
            (0x2B740...0x2B81F).contains(value) ||
            (0x2B820...0x2CEAF).contains(value) ||
            (0xF900...0xFAFF).contains(value) ||
            (0x2F800...0x2FA1F).contains(value)
    }
}
