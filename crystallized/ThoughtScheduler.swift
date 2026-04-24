//
//  ThoughtScheduler.swift
//  crystallized
//
//  Created by Max PRUDHOMME on 24/04/2026.
//

import Combine
import Foundation

private let webhookURLKey = "thoughtWebhookURL"
private let webhookSecretKeyKey = "thoughtWebhookSecretKey"

@MainActor
final class ThoughtScheduler: ObservableObject {
    let thoughtGenerator: ThoughtGenerator
    let webhookSender: WebhookSender

    private let generationDelayRange: ClosedRange<TimeInterval>
    private var task: Task<Void, Never>?

    init(generationDelayRange: ClosedRange<TimeInterval> = 60 * 60...180 * 60) {
        self.thoughtGenerator = ThoughtGenerator()
        self.webhookSender = WebhookSender()
        self.generationDelayRange = Self.developmentDelayRange ?? generationDelayRange

        start()
    }

    init(
        thoughtGenerator: ThoughtGenerator,
        webhookSender: WebhookSender,
        generationDelayRange: ClosedRange<TimeInterval> = 60 * 60...180 * 60
    ) {
        self.thoughtGenerator = thoughtGenerator
        self.webhookSender = webhookSender
        self.generationDelayRange = Self.developmentDelayRange ?? generationDelayRange

        start()
    }

    private static var developmentDelayRange: ClosedRange<TimeInterval>? {
        #if DEBUG
        return 15...45
        #else
        return nil
        #endif
    }

    deinit {
        task?.cancel()
    }

    private func start() {
        task?.cancel()

        let generationDelayRange = generationDelayRange
        task = Task { [weak self] in
            while !Task.isCancelled {
                let delay = TimeInterval.random(in: generationDelayRange)

                do {
                    try await Task.sleep(for: .seconds(delay))
                } catch {
                    return
                }

                guard let self else {
                    return
                }

                await self.generateAndSendThought()
            }
        }
    }

    private func generateAndSendThought() async {
        await thoughtGenerator.generateThought()

        let webhookURL = UserDefaults.standard.string(forKey: webhookURLKey) ?? ""
        guard !thoughtGenerator.thought.isEmpty, !webhookURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        let webhookSecretKey = UserDefaults.standard.string(forKey: webhookSecretKeyKey) ?? ""
        await webhookSender.send(thought: thoughtGenerator.thought, to: webhookURL, secretKey: webhookSecretKey)
    }
}
