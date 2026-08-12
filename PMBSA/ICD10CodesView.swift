//
//  ICD10CodesView.swift
//  PMBSA
//

import SwiftUI

/// Reference sheet listing the ICD-10 diagnosis codes relevant to lower-limb amputation and
/// prosthetic rehabilitation, organised by amputation level so a member can find the code that
/// matches the prosthetic components (socket, liner, knee, foot) their claim covers.
///
/// ICD-10 codes describe the *diagnosis* (amputation level and cause) that justifies PMB funding
/// — they are not the codes for the physical device components themselves. Those are billed
/// separately via NAPPI codes (see `HowToClaimView`, step 3 and step 6). This view surfaces that
/// distinction directly in its header so members don't conflate the two when talking to their
/// scheme or prosthetist.
struct ICD10CodesView: View {
    @Binding var isPresented: Bool
    @State private var searchText = ""

    private var filteredCategories: [ICD10Category] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return Self.categories }
        return Self.categories.compactMap { category in
            let matches = category.codes.filter {
                $0.code.lowercased().contains(query) || $0.description.lowercased().contains(query)
            }
            guard !matches.isEmpty else { return nil }
            return ICD10Category(title: category.title, components: category.components, codes: matches)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("ICD-10 codes describe the diagnosis (amputation level and cause) — they justify PMB funding but aren't the codes for the physical device. Your prosthetist bills the socket, liner, knee, and foot components separately using NAPPI codes. Always confirm the exact code with your surgeon, prosthetist, or scheme before submitting a claim.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                ForEach(filteredCategories) { category in
                    Section {
                        ForEach(category.codes) { code in
                            ICD10CodeRow(code: code)
                        }
                    } header: {
                        Text(category.title)
                    } footer: {
                        if let components = category.components {
                            Text("Relevant components: \(components)")
                        }
                    }
                }

                if filteredCategories.isEmpty {
                    Text("No matching codes. Try a different search term.")
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Search code or condition")
            .navigationTitle("ICD-10 Codes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { isPresented = false }
                }
            }
        }
        .presentationDetents([.large])
    }

    /// Lower-limb amputation and prosthetics reference codes, grouped by amputation level so the
    /// prosthetic components a member needs map directly onto the diagnosis category. WHO
    /// ICD-10 codes as used by South African medical schemes (not US ICD-10-CM).
    private static let categories: [ICD10Category] = [
        ICD10Category(
            title: "Above-Knee / Hip (Transfemoral)",
            components: "socket, knee unit, pylon, foot, liner",
            codes: [
                ICD10Code(code: "S78.0", description: "Traumatic amputation at hip joint"),
                ICD10Code(code: "S78.1", description: "Traumatic amputation at level between hip and knee"),
                ICD10Code(code: "S78.9", description: "Traumatic amputation of hip and thigh, level unspecified"),
                ICD10Code(code: "Z89.6", description: "Acquired absence of leg above knee")
            ]
        ),
        ICD10Category(
            title: "Below-Knee (Transtibial)",
            components: "socket, liner, pylon, foot",
            codes: [
                ICD10Code(code: "S88.0", description: "Traumatic amputation at knee level"),
                ICD10Code(code: "S88.1", description: "Traumatic amputation at level between knee and ankle"),
                ICD10Code(code: "S88.9", description: "Traumatic amputation of lower leg, level unspecified"),
                ICD10Code(code: "Z89.5", description: "Acquired absence of leg below knee")
            ]
        ),
        ICD10Category(
            title: "Foot & Ankle (Partial Foot / Syme's)",
            components: "partial-foot prosthesis or ankle-foot orthosis, foot shell",
            codes: [
                ICD10Code(code: "S98.0", description: "Traumatic amputation of foot at ankle level"),
                ICD10Code(code: "S98.1", description: "Traumatic amputation of one toe"),
                ICD10Code(code: "S98.2", description: "Traumatic amputation of two or more toes"),
                ICD10Code(code: "S98.3", description: "Traumatic amputation of other parts of foot"),
                ICD10Code(code: "S98.4", description: "Traumatic amputation of foot, level unspecified"),
                ICD10Code(code: "Z89.4", description: "Acquired absence of foot and ankle")
            ]
        ),
        ICD10Category(
            title: "General Amputation & Prosthetic-Fitting Status",
            components: nil,
            codes: [
                ICD10Code(code: "Z89.7", description: "Acquired absence of both lower limbs (any level)"),
                ICD10Code(code: "Z89.9", description: "Acquired absence of limb, unspecified"),
                ICD10Code(code: "Z44.1", description: "Fitting and adjustment of artificial leg (complete)(partial)"),
                ICD10Code(code: "Z97.1", description: "Presence of artificial limb (external)")
            ]
        ),
        ICD10Category(
            title: "Underlying / Causal Diagnoses",
            components: nil,
            codes: [
                ICD10Code(code: "E10.5", description: "Type 1 diabetes mellitus, with peripheral circulatory complications"),
                ICD10Code(code: "E11.5", description: "Type 2 diabetes mellitus, with peripheral circulatory complications"),
                ICD10Code(code: "I70.2", description: "Atherosclerosis of arteries of extremities"),
                ICD10Code(code: "I73.9", description: "Peripheral vascular disease, unspecified"),
                ICD10Code(code: "I74.3", description: "Embolism and thrombosis of arteries of the lower extremities"),
                ICD10Code(code: "C40.2", description: "Malignant neoplasm of long bones of lower limb"),
                ICD10Code(code: "C41.4", description: "Malignant neoplasm of pelvic bones, sacrum and coccyx"),
                ICD10Code(code: "Q72.0", description: "Congenital complete absence of lower limb(s)"),
                ICD10Code(code: "Q72.9", description: "Reduction defect of lower limb, unspecified")
            ]
        ),
        ICD10Category(
            title: "Stump & Prosthetic Complications",
            components: nil,
            codes: [
                ICD10Code(code: "T87.2", description: "Complications of amputation stump, not elsewhere classified"),
                ICD10Code(code: "T87.3", description: "Neuroma of amputation stump"),
                ICD10Code(code: "T87.4", description: "Infection of amputation stump"),
                ICD10Code(code: "T87.5", description: "Necrosis of amputation stump"),
                ICD10Code(code: "T87.6", description: "Other and unspecified complications of amputation stump")
            ]
        )
    ]
}

private struct ICD10Category: Identifiable {
    let title: String
    let components: String?
    let codes: [ICD10Code]
    var id: String { title }
}

private struct ICD10Code: Identifiable {
    let code: String
    let description: String
    var id: String { code }
}

private struct ICD10CodeRow: View {
    let code: ICD10Code

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(code.code)
                .font(.subheadline.bold().monospaced())
                .foregroundStyle(.blue)
            Text(code.description)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .textSelection(.enabled)
    }
}

#Preview {
    ICD10CodesView(isPresented: .constant(true))
}
