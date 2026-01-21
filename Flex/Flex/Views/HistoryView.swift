import SwiftUI

struct HistoryView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    // Empty state or workout history will go here
                    Spacer()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) {
                        Text("Calendar")
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
    }
}

#Preview {
    HistoryView()
}
