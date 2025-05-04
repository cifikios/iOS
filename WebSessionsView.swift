import SwiftUI

struct WebSession: Identifiable, Codable {
    let id = UUID()
    var duration: Double
    var notes: String
    var timestamp = Date()
    var isUploaded = false
}

struct WebSessionsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var sessions: [WebSession] = []
    @State private var showingAddSession = false
    @State private var newDuration = ""
    @State private var newNotes = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sessions) { session in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(String(format: "%.2f", session.duration)) sec")
                                .font(.headline)
                            Spacer()
                            if session.isUploaded {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        Text(session.notes)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text(session.timestamp.formatted())
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .swipeActions {
                        if !session.isUploaded {
                            Button {
                                uploadSession(session)
                            } label: {
                                Label("Upload", systemImage: "arrow.up")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .onDelete(perform: deleteSessions)
            }
            .navigationTitle("Web Sessions")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSession = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSession) {
                NavigationView {
                    Form {
                        Section(header: Text("New Session")) {
                            TextField("Duration (seconds)", text: $newDuration)
                                .keyboardType(.decimalPad)
                            TextField("Notes", text: $newNotes)
                        }
                    }
                    .navigationTitle("Add Session")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingAddSession = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                addNewSession()
                            }
                            .disabled(newDuration.isEmpty || Double(newDuration) == nil)
                        }
                    }
                }
            }
            .overlay {
                if isLoading {
                    ProgressView("Uploading...")
                        .padding()
                        .background(Color(.systemBackground).opacity(0.8))
                        .cornerRadius(10)
                }
            }
            .alert("Alert", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
        .onAppear {
            loadSessions()
        }
    }
    
    // MARK: - Session Management
    
    private func addNewSession() {
        guard let duration = Double(newDuration) else { return }
        
        let newSession = WebSession(
            duration: duration,
            notes: newNotes
        )
        
        sessions.append(newSession)
        saveSessions()
        newDuration = ""
        newNotes = ""
        showingAddSession = false
    }
    
    private func deleteSessions(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        saveSessions()
    }
    
    private func uploadSession(_ session: WebSession) {
        isLoading = true
        
        // Replace with your actual Flask server endpoint
        guard let url = URL(string: "http://moto.webhop.me/upload") else {
            showError("Invalid server URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "duration": session.duration,
            "notes": session.notes,
            "timestamp": session.timestamp.timeIntervalSince1970,
            "device": "iOS"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    isLoading = false
                    
                    if let error = error {
                        showError(error.localizedDescription)
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        showError("Server error")
                        return
                    }
                    
                    if let index = sessions.firstIndex(where: { $0.id == session.id }) {
                        sessions[index].isUploaded = true
                        saveSessions()
                        alertMessage = "Upload successful"
                        showAlert = true
                    }
                }
            }.resume()
        } catch {
            isLoading = false
            showError(error.localizedDescription)
        }
    }
    
    private func showError(_ message: String) {
        alertMessage = message
        showAlert = true
    }
    
    // MARK: - Persistence
    
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: "webSessions")
        }
    }
    
    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: "webSessions"),
           let decoded = try? JSONDecoder().decode([WebSession].self, from: data) {
            sessions = decoded
        }
    }
}

struct WebSessionsView_Previews: PreviewProvider {
    static var previews: some View {
        WebSessionsView()
    }
}
