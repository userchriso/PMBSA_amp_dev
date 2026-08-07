//
//  PMBAssistantView.swift
//  PMBSA
//

import SwiftUI

struct PMBAssistantView: View {
    @State private var service = ClaudeService()
    @State private var inputText = ""
    @Binding var isPresented: Bool
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messageList
                Divider()
                inputBar
            }
            .navigationTitle("PMB Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { isPresented = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        service.clearHistory()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(service.messages.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if service.messages.isEmpty {
                        WelcomeCard { suggestion in
                            inputText = suggestion
                            sendMessage()
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                    }

                    ForEach(service.messages) { msg in
                        BubbleView(message: msg)
                            .padding(.horizontal)
                            .id(msg.id)
                    }

                    if service.isLoading {
                        TypingIndicatorView()
                            .padding(.horizontal)
                            .id("typing")
                    }

                    if let error = service.errorMessage {
                        ErrorView(text: error)
                            .padding(.horizontal)
                    }

                    Color.clear.frame(height: 8).id("bottom")
                }
                .padding(.bottom, 4)
            }
            .onChange(of: service.messages.count) {
                withAnimation { proxy.scrollTo("bottom") }
            }
            .onChange(of: service.isLoading) {
                if service.isLoading {
                    withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                }
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Ask about PMBs...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .focused($inputFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 22))

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(canSend ? .blue : .gray)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty && !service.isLoading
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputText = ""
        inputFocused = false
        Task { await service.send(text) }
    }
}

// MARK: - Subviews

struct WelcomeCard: View {
    let onSuggestion: (String) -> Void

    private let suggestions = [
        "What are PMBs?",
        "Am I covered for a prosthetic limb?",
        "How do I appeal a rejected PMB claim?",
        "What is the CDL, and how is it different from my PMBs?",
        "How often can I claim for a replacement prosthetic limb?",
        "Can my medical aid refuse to pay for a prosthetic upgrade?",
        "What documents do I need to submit a PMB claim?",
        "What happens if my scheme runs out of prosthetic benefits mid-year?"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "stethoscope.circle.fill")
                    .font(.title)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("PMB Assistant")
                        .font(.headline)
                    Text("Powered by Claude AI")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text("Ask me anything about Prescribed Minimum Benefits — coverage, claims, prosthetics, appeals, or your rights as a medical aid member.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Try asking:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 2)

                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        onSuggestion(suggestion)
                    } label: {
                        HStack {
                            Text(suggestion)
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.blue.opacity(0.6))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct BubbleView: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser {
                Spacer(minLength: 60)
            } else {
                Image(systemName: "stethoscope.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 28)
            }

            Text(message.content)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isUser ? Color.blue : Color(.systemGray5))
                .foregroundStyle(isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .textSelection(.enabled)

            if !isUser {
                Spacer(minLength: 60)
            }
        }
    }
}

struct TypingIndicatorView: View {
    @State private var phase = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Image(systemName: "stethoscope.circle.fill")
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 28)

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.gray.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .scaleEffect(phase ? 1.3 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.18),
                            value: phase
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Spacer(minLength: 60)
        }
        .onAppear { phase = true }
    }
}

struct ErrorView: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    PMBAssistantView(isPresented: .constant(true))
}
