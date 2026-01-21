import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // User Profile Section
                    HStack {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.gray)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Kevin")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("1002 workouts")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.blue)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    // Dashboard Section
                    HStack {
                        Text("Dashboard")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Label("Widget", systemImage: "plus")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Workouts Per Week Widget
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Workouts Per Week")
                                    .font(.headline)
                                Text("Activity")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Image(systemName: "target")
                                    .foregroundStyle(.blue)
                            }
                            
                            Button(action: {}) {
                                Image(systemName: "ellipsis")
                                    .foregroundStyle(.blue)
                            }
                        }
                        
                        HStack {
                            Spacer()
                            Text("3")
                                .font(.title3)
                                .foregroundStyle(.purple)
                        }
                        
                        // Simple bar chart placeholder
                        HStack(alignment: .bottom, spacing: 20) {
                            VStack {
                                Rectangle()
                                    .fill(Color.purple.opacity(0.6))
                                    .frame(width: 30, height: 100)
                                Text("11/17")
                                    .font(.caption2)
                            }
                            Spacer()
                        }
                        .frame(height: 120)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 16) {
                        Button(action: {}) {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(.blue)
                        }
                        Button(action: {}) {
                            Image(systemName: "ruler.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}
