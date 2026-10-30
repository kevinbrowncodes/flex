import SwiftUI
import SwiftData

struct CreateFolderPopup: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @State private var folderName = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Popup content
            VStack(spacing: 24) {
                Text("Add New Folder")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                TextField("New Folder", text: $folderName)
                    .textFieldStyle(.roundedBorder)
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        createFolder()
                    }
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary)
                    .cornerRadius(12)
                    
                    Button("Save") {
                        createFolder()
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary : Color.blue)
                    .cornerRadius(12)
                    .disabled(folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 20)
            .padding(.horizontal, 40)
            .onAppear {
                // Focus the text field when the popup appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTextFieldFocused = true
                }
            }
        }
    }
    
    private func createFolder() {
        let trimmedName = folderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let newFolder = TemplateFolder(name: trimmedName)
        modelContext.insert(newFolder)
        
        do {
            try modelContext.save()
            isPresented = false
        } catch {
            // Handle error - could add error state/alert here
            print("Failed to save folder: \(error)")
        }
    }
}

#Preview {
    CreateFolderPopup(isPresented: .constant(true))
}