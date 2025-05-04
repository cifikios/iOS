import SwiftUI

struct HistoryView: View {
    @Binding var sessions: [LocationSession]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sessions) { session in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Session: \(session.date.formatted())")
                            .font(.headline)
                        
                        // Display Total Time
                        Text("Total Time: \(session.totalTime)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        // Display Lap Times
                        if !session.lapTimes.isEmpty {
                            Text("Lap Times:")
                                .font(.subheadline)
                                .padding(.top, 4)
                            
                            ForEach(Array(session.lapTimes.enumerated()), id: \.offset) { index, lapTime in
                                Text(lapTime)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                // Display Sector Times for this Lap
                                if let sectorTimes = session.sectorTimes, sectorTimes.count > index {
                                    ForEach(Array(sectorTimes[index].enumerated()), id: \.offset) { sectorIndex, sectorTime in
                                        Text(sectorTime)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .padding(.leading, 16)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .navigationTitle("Lap/Sector History")
        }
    }
}
