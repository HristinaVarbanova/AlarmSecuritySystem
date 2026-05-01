import Foundation

final class ESP32Service {
    static let shared = ESP32Service()

    private init() {}

    // Смени това с IP адреса на твоя ESP32
    private let baseURL = "http://192.168.4.1"

    func armSystem() async throws {
        try await sendRequest(endpoint: "/arm")
    }

    func disarmSystem() async throws {
        try await sendRequest(endpoint: "/disarm")
    }

    private func sendRequest(endpoint: String) async throws {
        guard let url = URL(string: baseURL + endpoint) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
