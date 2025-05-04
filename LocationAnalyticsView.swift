import SwiftUI

struct LocationAnalyticsView: View {
    @Binding var sessions: [LocationSession]
    var saveSessions: ([LocationSession]) -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(sessions) { session in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Session: \(session.date.formatted())")
                                .font(.system(size: 16, weight: .bold))
                            Text("Fastest Lap: \(session.fastestLap)")
                            Text("Slowest Lap: \(session.slowestLap)")
                            Text("Average Lap: \(session.averageLap)")
                            Text("Consistency: \(session.consistency)")
                            Text("Total Time: \(session.totalTime)")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            if let city = session.location {
                                Text("Location: \(city)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            Button(action: {
                                if let index = sessions.firstIndex(where: { $0.id == session.id }) {
                                    sessions.remove(at: index)
                                    saveSessions(sessions)
                                }
                            }) {
                                Text("Delete")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Analytics")
        }
    }
}
