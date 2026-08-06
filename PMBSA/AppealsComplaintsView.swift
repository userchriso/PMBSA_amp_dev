//
//  AppealsComplaintsView.swift
//  PMBSA
//

import SwiftUI

struct AppealsComplaintsView: View {
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Medical Scheme Appeals & Complaints")
                            .font(.title2.bold())
                        Text("What to do if your PMB claim is refused, and how to escalate it.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)

                    AppealStepCard(
                        number: 1,
                        title: "Appeal internally, with your scheme, first",
                        color: .blue
                    ) {
                        Text("The Council for Medical Schemes (CMS) requires you to exhaust your scheme's internal dispute process before they'll accept a complaint. Submit your appeal in writing, citing the PMB regulations, with:")
                            .font(.subheadline)
                        BulletList(items: [
                            "A signed, completed appeal form (from your scheme's PMB/appeals department)",
                            "Supporting clinical documentation and motivation from your doctor/prosthetist",
                            "Detailed invoices and referral letters"
                        ])
                        Text("Most schemes resolve internal appeals within ~30 days. Most denials are procedural (missing documentation, wrong codes) rather than valid refusals — a properly-motivated appeal usually succeeds at this stage.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    AppealStepCard(
                        number: 2,
                        title: "Escalate to the Council for Medical Schemes (CMS)",
                        color: .teal
                    ) {
                        Text("If your scheme's internal appeal doesn't resolve it, or you disagree with the outcome, escalate to CMS — the independent statutory regulator.")
                            .font(.subheadline)
                        Text("Submit via:")
                            .font(.subheadline.bold())
                            .padding(.top, 4)
                        BulletList(items: [
                            "Email: complaints@medicalschemes.co.za",
                            "Post: The Council for Medical Schemes: Complaints Adjudication Unit, Private Bag X34, Hatfield, 0028",
                            "In person at CMS offices"
                        ])
                        Text("You'll need: the completed CMS complaint form, a detailed account of the facts and what you want resolved, proof you already escalated internally, and any clinical reports/statements.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }

                    AppealStepCard(
                        number: 3,
                        title: "What happens after you submit",
                        color: .orange
                    ) {
                        BulletList(items: [
                            "Within 6 working days: written acknowledgement + reference number + assigned contact person",
                            "Within 4 working days of that: your complaint is analysed and referred to your scheme",
                            "Within 30 days: your scheme must respond in writing",
                            "Within 120 calendar days total: CMS aims to resolve the matter"
                        ])
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Key Contacts")
                            .font(.headline)
                        ContactRow(label: "CMS Phone", value: "0861 123 267")
                        ContactRow(label: "CMS Phone (alt)", value: "+27 12 431 0500")
                        ContactRow(label: "CMS Email", value: "complaints@medicalschemes.co.za")
                        ContactRow(label: "Hours", value: "Mon–Fri, 8:00–16:30")
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .navigationTitle("Appeals / Complaints")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { isPresented = false }
                }
            }
        }
        .presentationDetents([.large])
    }
}

private struct AppealStepCard<Content: View>: View {
    let number: Int
    let title: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 28, height: 28)
                    Text("\(number)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                }
                Text(title)
                    .font(.headline)
            }
            content
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct BulletList: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                    Text(item)
                }
                .font(.subheadline)
            }
        }
    }
}

private struct ContactRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .textSelection(.enabled)
        }
    }
}

#Preview {
    AppealsComplaintsView(isPresented: .constant(true))
}
