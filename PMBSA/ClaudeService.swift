//
//  ClaudeService.swift
//  PMBSA
//

import Foundation

/// A single turn in the PMB Assistant chat, in the shape the Anthropic Messages API expects.
///
/// `role` is either `"user"` or `"assistant"` — it's sent verbatim in the request body's
/// `messages` array (see `ClaudeService.callAPI()`), so it must stay one of those two literal
/// strings.
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String
    let content: String
}

/// Drives the PMB Assistant chat feature by calling the Anthropic Messages API directly from
/// the client (no backend proxy).
///
/// Requires `Secrets.claudeAPIKey` to be set — see `PMBSA/Secrets.swift`, which is gitignored
/// and must be created locally before this will compile (see repo README).
///
/// Because the API key ships inside the app binary, it is extractable by anyone who inspects
/// the shipped build. There is currently no server-side proxy hiding it.
@Observable
class ClaudeService {
    /// Full conversation history for the current chat session, oldest first. Cleared by
    /// `clearHistory()`. The entire array is resent as context on every `send(_:)` call, so it
    /// also determines the size (and cost) of each request.
    var messages: [ChatMessage] = []
    /// True while a request to the Anthropic API is in flight. Drives the typing indicator in
    /// `PMBAssistantView`.
    var isLoading = false
    /// Set to a user-facing message when the last `send(_:)` call failed. `nil` when there's no
    /// active error. Cleared automatically at the start of the next `send(_:)` call and by
    /// `clearHistory()`.
    var errorMessage: String?

    private let apiKey = Secrets.claudeAPIKey
    /// Anthropic model ID used for every request. Update here if the model needs to change.
    private let model = "claude-haiku-4-5-20251001"

    /// Fixed system prompt sent with every request. Specializes the assistant in South African
    /// PMB/CDL/DTP rules, prosthetics/orthotics coverage, claims/appeals, ICD-10 codes for
    /// lower-limb amputation (mirroring `ICD10CodesView`), and the 7 medical schemes listed
    /// below. Everything else the assistant "knows" beyond this prompt comes from the model
    /// itself.
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
    - ICD-10 diagnosis codes for lower-limb amputation, organised by level and cause (WHO ICD-10, as used by SA schemes — not US ICD-10-CM). These justify PMB funding for the matching prosthetic components (socket, liner, knee unit, foot), which are themselves billed separately via NAPPI codes:
      - Above-knee/hip (transfemoral — socket, knee unit, pylon, foot, liner): S78.0, S78.1, S78.9, Z89.6
      - Below-knee (transtibial — socket, liner, pylon, foot): S88.0, S88.1, S88.9, Z89.5
      - Foot/ankle (partial foot or Syme's): S98.0–S98.4, Z89.4
      - General amputation/prosthetic-fitting status: Z89.7, Z89.9, Z44.1 (fitting/adjustment of artificial leg), Z97.1 (presence of artificial limb)
      - Underlying causes: E10.5/E11.5 (diabetic peripheral circulatory complications), I70.2 (atherosclerosis of extremities), I73.9 (peripheral vascular disease), I74.3 (arterial embolism/thrombosis of lower extremities), C40.2/C41.4 (malignant bone neoplasm), Q72.0/Q72.9 (congenital lower-limb reduction defects)
      - Stump/prosthetic complications: T87.2 (stump complications NEC), T87.3 (neuroma), T87.4 (infection), T87.5 (necrosis), T87.6 (other/unspecified)
      When asked about codes, always clarify that the ICD-10 code is the diagnosis justifying the claim, not the code for the physical device — and recommend confirming the exact code with the treating doctor or prosthetist, since only they can assign it accurately for a specific patient.

    Always give accurate, practical advice. Keep answers clear and concise — members are often frustrated and need straightforward help. Remind users that specific benefit details should be confirmed with their scheme.

    Never provide specific medical advice — recommend consulting a healthcare provider or prosthetist for clinical decisions.
    """

    /// Appends `userText` to `messages` as a user turn, calls the Anthropic API with the full
    /// conversation so far, and appends the reply (or sets `errorMessage`) when it returns.
    ///
    /// Always sets `isLoading = true` for the duration of the call and clears any previous
    /// `errorMessage` before starting, regardless of outcome. On failure, `errorMessage` is set
    /// to a generic connectivity message — the underlying error (HTTP status, decode failure,
    /// etc.) is swallowed, not surfaced. The user's message stays in `messages` even if the
    /// call fails, so retry means calling `send(_:)` again rather than resending the same turn.
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

    /// Resets the chat: clears `messages` and `errorMessage`. Causes `PMBAssistantView` to show
    /// the `WelcomeCard` again since it keys off `messages.isEmpty`.
    func clearHistory() {
        messages = []
        errorMessage = nil
    }

    /// Sends the current `messages` array plus `systemPrompt` to the Anthropic Messages API and
    /// returns the assistant's reply text.
    ///
    /// - Throws: `URLError(.badURL)` if the endpoint URL fails to construct (should never
    ///   happen in practice); `NSError(domain: "ClaudeAPI", code: <HTTP status>)` on any non-200
    ///   response; a decoding error if the response body doesn't match `AnthropicResponse`.
    /// - Returns: The text of the first content block in the response, or `"No response
    ///   received."` if the API returned an empty `content` array.
    /// - Note: 30-second request timeout (`request.timeoutInterval`). Every call resends the
    ///   full `messages` history as context — there's no truncation/windowing, so very long
    ///   sessions grow the request payload and token cost accordingly.
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

/// Minimal decode target for the Anthropic Messages API response — only pulls out what
/// `callAPI()` needs (the reply text). Does not model token usage, stop reason, message ID, etc.
private struct AnthropicResponse: Codable {
    let content: [AnthropicContent]
}

/// One content block from an Anthropic response. `type` is decoded but unused — `callAPI()`
/// only reads `text`, so this assumes the response is plain text (no tool-use or image blocks).
private struct AnthropicContent: Codable {
    let text: String
    let type: String
}
