//
//  WebhookSender.swift
//  crystallized
//
//  Created by Max PRUDHOMME on 24/04/2026.
//

import Combine
import Darwin
import Foundation

private let postFailureMessage = "Could not POST to the endpoint."

@MainActor
final class WebhookSender: ObservableObject {
    @Published private(set) var isSending = false
    @Published private(set) var statusMessage: String?

    func send(thought: String, to urlString: String) async {
        guard !urlString.trimmed.isEmpty else {
            statusMessage = "Enter a webhook URL."
            return
        }

        guard let url = URL(httpURLString: urlString) else {
            statusMessage = "Enter a valid HTTP URL."
            return
        }

        isSending = true
        statusMessage = "Sending..."
        defer { isSending = false }

        guard url.acceptsLoopbackConnection else {
            statusMessage = postFailureMessage
            debugPrint(postFailureMessage)
            return
        }

        do {
            let (_, response) = try await URLSession.shared.data(for: request(thought: thought, url: url))
            if let statusCode = response.failedHTTPStatusCode {
                statusMessage = "POST failed with \(statusCode)."
            } else {
                statusMessage = "Sent."
            }
        } catch {
            statusMessage = error.webhookMessage
            debugPrint(statusMessage ?? "Its not working")
        }
    }

    private func request(thought: String, url: URL) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(WebhookPayload(thought: thought))
        return request
    }
}

private struct WebhookPayload: Encodable {
    let thought: String
}

private extension URL {
    init?(httpURLString string: String) {
        self.init(string: string.trimmed)

        let scheme = scheme?.lowercased()
        guard scheme == "http" || scheme == "https" else {
            return nil
        }
    }
}

private extension URLResponse {
    var failedHTTPStatusCode: Int? {
        guard let httpResponse = self as? HTTPURLResponse else {
            return nil
        }

        return (200..<300).contains(httpResponse.statusCode) ? nil : httpResponse.statusCode
    }
}

private extension Error {
    var webhookMessage: String {
        guard let urlError = self as? URLError else {
            return localizedDescription
        }

        switch urlError.code {
        case .cannotConnectToHost, .cannotFindHost, .networkConnectionLost, .notConnectedToInternet, .timedOut:
            return postFailureMessage
        default:
            return localizedDescription
        }
    }
}

private extension URL {
    var acceptsLoopbackConnection: Bool {
        guard
            let host,
            host.isIPv4LoopbackAddress,
            let port = port ?? defaultPort
        else {
            return true
        }

        return SocketProbe.canConnect(to: host, port: port)
    }

    var defaultPort: Int? {
        switch scheme?.lowercased() {
        case "http":
            return 80
        case "https":
            return 443
        default:
            return nil
        }
    }
}

private enum SocketProbe {
    static func canConnect(to host: String, port: Int) -> Bool {
        let fileDescriptor = socket(AF_INET, SOCK_STREAM, 0)
        guard fileDescriptor >= 0 else {
            return false
        }
        defer { close(fileDescriptor) }

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = in_port_t(port).bigEndian

        guard inet_pton(AF_INET, host, &address.sin_addr) == 1 else {
            return false
        }

        let result = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { socketAddress in
                connect(fileDescriptor, socketAddress, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        return result == 0
    }
}

private extension String {
    var isIPv4LoopbackAddress: Bool {
        self == "127.0.0.1" || hasPrefix("127.")
    }

    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
