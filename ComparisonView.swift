import SwiftUI

struct CompareView: View {
    @Binding var sessions: [LocationSession]
    @Binding var selectedSessions: [UUID]
    @State private var comparisonType: ComparisonType = .session
    
    enum ComparisonType {
        case session, lap, sector
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Comparison Type", selection: $comparisonType) {
                    Text("Sessions").tag(ComparisonType.session)
                    Text("Laps").tag(ComparisonType.lap)
                    Text("Sectors").tag(ComparisonType.sector)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if comparisonType == .session {
                    SessionComparisonView(sessions: $sessions, selectedSessions: $selectedSessions)
                } else if comparisonType == .lap {
                    LapComparisonView(sessions: $sessions, selectedSessions: $selectedSessions)
                } else {
                    SectorComparisonView(sessions: $sessions, selectedSessions: $selectedSessions)
                }
            }
            .navigationTitle("Compare")
        }
    }
}

struct SessionComparisonView: View {
    @Binding var sessions: [LocationSession]
    @Binding var selectedSessions: [UUID]
    
    var body: some View {
        List {
            ForEach(sessions) { session in
                HStack {
                    Text("Session: \(session.date.formatted())")
                    Spacer()
                    if selectedSessions.contains(session.id) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedSessions.contains(session.id) {
                        selectedSessions.removeAll { $0 == session.id }
                    } else {
                        selectedSessions.append(session.id)
                    }
                }
            }
        }
    }
}

struct LapComparisonView: View {
    @Binding var sessions: [LocationSession]
    @Binding var selectedSessions: [UUID]
    
    var body: some View {
        List {
            ForEach(sessions.filter { selectedSessions.contains($0.id) }) { session in
                Section(header: Text("Session: \(session.date.formatted())")) {
                    ForEach(session.lapTimes.indices, id: \.self) { index in
                        Text("Lap \(index + 1): \(session.lapTimes[index])")
                    }
                }
            }
        }
    }
}

struct SectorComparisonView: View {
    @Binding var sessions: [LocationSession]
    @Binding var selectedSessions: [UUID]
    
    var body: some View {
        List {
            ForEach(sessions.filter { selectedSessions.contains($0.id) }) { session in
                Section(header: Text("Session: \(session.date.formatted())")) {
                    if let sectorTimes = session.sectorTimes {
                        ForEach(sectorTimes.indices, id: \.self) { lapIndex in
                            ForEach(sectorTimes[lapIndex].indices, id: \.self) { sectorIndex in
                                Text("Lap \(lapIndex + 1), Sector \(sectorIndex + 1): \(sectorTimes[lapIndex][sectorIndex])")
                            }
                        }
                    }
                }
            }
        }
    }
}
