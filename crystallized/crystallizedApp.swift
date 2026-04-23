//
//  crystallizedApp.swift
//  crystallized
//
//  Created by Max PRUDHOMME on 23/04/2026.
//

import SwiftUI

@main
struct crystallizedApp: App {
    @StateObject private var thoughtScheduler = ThoughtScheduler()

    var body: some Scene {
        MenuBarExtra("Crystallized", systemImage: "sparkles") {
            ContentView(
                thoughtGenerator: thoughtScheduler.thoughtGenerator,
                webhookSender: thoughtScheduler.webhookSender
            )
        }
        .menuBarExtraStyle(.window)
    }
}
