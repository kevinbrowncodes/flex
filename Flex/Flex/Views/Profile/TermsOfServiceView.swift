import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) var dismiss
    @State private var terms: TermsOfService?
    
    var body: some View {
        ScrollView {
            if let terms = terms {
                VStack(alignment: .leading, spacing: 24) {
                    // Title
                    Text(terms.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 8)
                    
                    // Introduction
                    ForEach(Array(terms.introduction.enumerated()), id: \.offset) { _, paragraph in
                        Text(paragraph)
                    }
                    
                    Divider()
                    
                    // Sections
                    ForEach(terms.sections) { section in
                        sectionView(section: section)
                        Divider()
                    }
                    
                    // Last Updated
                    Text("Last Updated: \(terms.lastUpdated)")
                        .font(.body)
                }
                .padding()
            } else {
                ProgressView("Loading Terms of Service...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadTerms()
        }
    }
    
    @ViewBuilder
    private func sectionView(section: TermsSection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(section.number). \(section.title)")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(section.content)
                .font(.body)
                .lineSpacing(4)
        }
    }
    
    private func loadTerms() {
        guard let url = Bundle.main.url(forResource: "TermsOfService", withExtension: "json") else {
            print("Failed to locate TermsOfService.json")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            terms = try decoder.decode(TermsOfService.self, from: data)
        } catch {
            print("Failed to load terms: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        TermsOfServiceView()
    }
}
