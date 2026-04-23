//
//  ThoughtGenerator.swift
//  crystallized
//
//  Created by Max PRUDHOMME on 23/04/2026.
//

import Combine
import Foundation
import FoundationModels

@MainActor
final class ThoughtGenerator: ObservableObject {
    @Published private(set) var thought = ""
    @Published private(set) var isGenerating = false
    @Published private(set) var statusMessage: String?

    private let model: SystemLanguageModel?
    private let prompt = "Write one strange, cryptic thought for this exact moment."
    private let instructions = """
    You write short reflective thoughts for a quiet macOS menu bar app.
    Make each thought mystic, weird, and interesting, like a small omen found in the machinery of the day.
    Avoid business-casual coaching, productivity advice, and obvious reassurance.
    Respond with one or two compact sentences. Keep it vivid, elliptical, and human-readable.
    """

    var canGenerate: Bool {
        model?.isAvailable == true && !isGenerating
    }

    init() {
        self.model = SystemLanguageModel.default
        updateAvailabilityStatus()
    }

    init(thought: String, statusMessage: String? = nil, isGenerating: Bool = false) {
        self.thought = thought
        self.statusMessage = statusMessage
        self.isGenerating = isGenerating
        self.model = nil
    }

    func generateThought() async {
        guard !isGenerating else {
            return
        }

        guard let model else {
            return
        }

        guard case .available = model.availability else {
            updateAvailabilityStatus()
            return
        }

        isGenerating = true
        statusMessage = "Thinking..."
        defer { isGenerating = false }

        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt)

            thought = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            statusMessage = nil
        } catch {
            thought = "Unable to generate a thought right now."
            statusMessage = error.localizedDescription
        }
    }

    private func updateAvailabilityStatus() {
        guard let model else {
            return
        }

        switch model.availability {
        case .available:
            statusMessage = "Apple Intelligence is ready."
        case .unavailable(let reason):
            statusMessage = "Apple Intelligence unavailable: \(reason)"
        @unknown default:
            statusMessage = "Apple Intelligence availability is unknown."
        }
    }
}

private extension SystemLanguageModel {
    var isAvailable: Bool {
        if case .available = availability {
            return true
        }

        return false
    }
}
