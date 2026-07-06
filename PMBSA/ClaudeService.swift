//
//  ClaudeService.swift
//  PMBSA
//

import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String
    let content: String
}

@Observable
class ClaudeService {
    var messages: [ChatMessage] = []
    var isLoading = false
    var errorMessage: String?

    private let apiKey = Secrets.claudeAPIKey
    private let model = "claude-haiku-4-5-20251001"

    private let systemPrompt = """
    You are a specialist assistant for Prescribed Minimum Benefits (PMBs) in South Africa, with a particular focus on prosthetics and orthotics coverage for amputees and people with limb differences.

    You help patients and medical aid members understand:
    - What PMBs are under the Medical Schemes Act 131 of 1998
    - The 270 Diagnosis Treatment Pairs (DTPs) covered as PMBs
    - The Chronic Disease List (CDL) — 26 chronic conditions that must be covered
    - PMB coverage for prosthetics, orthotics, and assistive devices
    - How amputees and people requiring prosthetic limbs can access PMB benefits
    - Claim submission steps and required documentation
    - Members' rights — schemes cannot apply co-payments or limit funds for PMB conditions at DTP level
    - Designated Healthcare Service Providers (DHCSPs) and how to use them
    - What to do if a scheme denies or limits a PMB claim
    - How to appeal a rejected claim
    - The role of the Council for Medical Schemes (CMS) in resolving disputes
    - How major SA schemes handle PMB claims: Discovery Health, Bonitas, Fedhealth, Momentum Health, Bestmed, Medshield, GEMS

    Always give accurate, practical advice. Keep answers clear and concise — members are often frustrated and need straightforward help. Remind users that specific benefit details should be confirmed with their scheme.

    Never provide specific medical advice — recommend consulting a healthcare provider or prosthetist for clinical decisions.
    """

    func send(_ userText: String) async {
        let userMsg = ChatMessage(role: "user", content: userText)
        messages.append(userMsg)
        isLoading = true
        errorMessage = nil

        do {
            let reply = try await callAPI()
            messages.append(ChatMessage(role: "assistant", content: reply))
        } catch {
            errorMessage = "Could not reach the assistant. Check your connection and try again."
        }

        isLoading = false
    }

    func clearHistory() {
        messages = []
        errorMessage = nil
    }

    private func callAPI() async throws -> String {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let apiMessages = messages.map { ["role": $0.role, "content": $0.content] }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "system": systemPrompt,
            "messages": apiMessages
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw NSError(domain: "ClaudeAPI", code: statusCode)
        }

        let decoded = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        return decoded.content.first?.text ?? "No response received."
    }
}

private struct AnthropicResponse: Codable {
    let content: [AnthropicContent]
}

private struct AnthropicContent: Codable {
    let text: String
    let type: String
}
