import SwiftUI

struct SessionSelectionView: View {
    @Binding var sessions: [LocationSession]
    @Binding var selectedSessions: [UUID]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sessions) { session in
                    HStack {
                        Text("Session: \(session.date.formatted())")
                        Spacer()
                        Button(action: {
                            if selectedSessions.contains(session.id) {
                                selectedSessions.removeAll { $0 == session.id }
                            } else {
                                selectedSessions.append(session.id)
                            }
                        }) {
                            Image(systemName: selectedSessions.contains(session.id) ? "checkmark.circle.fill" : "circle")
                        }
                    }
                }
            }
            .navigationTitle("Select Sessions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
