//
//  HowToClaimView.swift
//  PMBSA
//

import SwiftUI

struct HowToClaimView: View {
    @Binding var isPresented: Bool

    private let steps: [ClaimStep] = [
        ClaimStep(
            number: 1,
            title: "Confirm your amputation qualifies as a PMB condition",
            body: "Speak to your surgeon or GP. Ask them to confirm the ICD-10 code for your amputation and whether it links to a PMB condition. Common codes: traumatic (S48, S58, S68, S78, S88, S98), diabetic vascular (E11), peripheral vascular disease (I70–I79)."
        ),
        ClaimStep(
            number: 2,
            title: "Contact your medical scheme's PMB department",
            body: "Phone your scheme and specifically ask for the PMB team or chronic/managed care division. Say: \"I need to apply for PMB cover for a prosthetic limb following amputation.\" Request the PMB application forms."
        ),
        ClaimStep(
            number: 3,
            title: "Complete the PMB application forms",
            body: "Three parties must provide input: you (member section), your doctor or surgeon (clinical motivation — diagnosis, treatment necessity, prognosis), and your prosthetist (device specification, quotation, NAPPI codes for all components)."
        ),
        ClaimStep(
            number: 4,
            title: "Submit and track your application",
            body: "Submit everything together — incomplete applications cause delays. Note your reference number. Your scheme is legally required to respond within 60 days. Follow up at 30 days if you have not heard back."
        ),
        ClaimStep(
            number: 5,
            title: "Obtain pre-authorisation before your fitting",
            body: "Once approved, your scheme will issue a pre-authorisation number. This must be in place before your prosthetist begins fabrication. No exceptions. Without it, your claim can be rejected."
        ),
        ClaimStep(
            number: 6,
            title: "Proceed with fitting and claim",
            body: "Your prosthetist submits the claim to your scheme using your pre-auth number, the NAPPI codes for all prosthetic components (socket, liner, foot/knee, adapters), and the ICD-10 diagnosis code. Keep copies of everything."
        ),
        ClaimStep(
            number: 7,
            title: "Appeal if you are refused",
            body: "If your PMB claim is denied, you can appeal — first to your scheme's internal appeals process, then to the Council for Medical Schemes (CMS): 0861 123 267 or complaints@medicalschemes.co.za. A valid PMB refusal is rare. Most denials are procedural and reversible."
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("How to Claim Your PMB")
                            .font(.title2.bold())
                        Text("Step by step, from diagnosis to a successful claim.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(steps) { step in
                            StepRow(step: step, isLast: step.id == steps.last?.id)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .navigationTitle("How to Claim")
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

private struct ClaimStep: Identifiable {
    let number: Int
    let title: String
    let body: String
    var id: Int { number }
}

private struct StepRow: View {
    let step: ClaimStep
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 32, height: 32)
                    Text("\(step.number)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                }
                if !isLast {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 2)
                        .frame(minHeight: 24)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.subheadline.bold())
                Text(step.body)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, isLast ? 0 : 20)
        }
    }
}

#Preview {
    HowToClaimView(isPresented: .constant(true))
}
