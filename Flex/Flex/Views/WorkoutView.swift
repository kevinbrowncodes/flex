import SwiftUI

struct WorkoutView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Button(action: {}) {
                    Text("Start Workout")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding()
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Start Workout")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    WorkoutView()
}
