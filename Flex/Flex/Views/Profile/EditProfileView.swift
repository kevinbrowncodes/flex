import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(PreferencesManager.self) private var preferencesManager
    @Environment(AuthenticationManager.self) private var authManager
    @State private var name: String = ""
    @State private var originalName: String = ""

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && trimmedName != originalName
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.gray)
                            )
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(originalName.isEmpty ? "User" : originalName)
                                .font(.headline)
                            if let email = authManager.userEmail {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.body)
                            .fontWeight(.semibold)

                        TextField("Your name", text: $name)
                            .textFieldStyle(.plain)
                            .textContentType(.name)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .accessibilityIdentifier("profile-name")
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.vertical)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel("Cancel")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        preferencesManager.setUserName(trimmedName)
                        dismiss()
                    }
                    .disabled(!canSave)
                    .accessibilityIdentifier("save-profile")
                }
            }
            .onAppear {
                // Priority: custom name > name from Sign in with Apple.
                let current = preferencesManager.userName ?? authManager.userFullName ?? ""
                name = current
                originalName = current
            }
        }
    }
}

#Preview {
    EditProfileView()
        .environment(ThemeManager())
        .environment(PreferencesManager())
        .environment(AuthenticationManager())
}
