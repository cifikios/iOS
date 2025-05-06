import SwiftUI
import MapKit
import CoreLocation
import Firebase
import FirebaseDatabase

struct ContentView: View {
    // MARK: - Properties
    @StateObject private var locationManager = LocationManager()
    @State private var isRunning = false
    @State private var startTime = Date()
    @State private var lapStartTime = Date()
    @State private var sectorStartTime = Date()
    @State private var totalTime = "00:00:00"
    @State private var currentLap = "00:00:00"
    @State private var bestLap = "00:00:00"
    @State private var lapTimes: [String] = []
    @State private var sectorTimes: [[String]] = []
    @State private var bestLapTime: TimeInterval = .infinity
    @State private var lapCount = 0
    @State private var sectorCount = 0
    @State private var timer: Timer?
    @State private var isFirstLap = true
    @State private var mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    @State private var sectorMarkers: [CLLocationCoordinate2D] = []
    @State private var sessions: [LocationSession] = []
    @State private var showAnalytics = false
    @State private var showComparison = false
    @State private var showComparisonResults = false
    @State private var showHistory = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var selectedSessions: [UUID] = []
    
    // Menu and Session States
    @State private var showMenu = false
    @State private var showResetOptions = false
    @State private var isUploading = false
    @State private var uploadMessage = ""
    @State private var showUploadAlert = false
    @State private var showLiveSessionOptions = false
    @State private var liveSessionStatus = "Not Active"
    @State private var isLiveSessionActive = false
    @State private var autoStartLiveSession = UserDefaults.standard.bool(forKey: "autoStartLiveSession")
    @State private var username = UserDefaults.standard.string(forKey: "username") ?? ""
    @State private var showUsernameDialog = false
    @State private var liveSessionRef: DatabaseReference?
    @State private var liveSessionTimer: Timer?

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Header
                    Text("Moto StopWatch Lap/Sector")
                        .font(.system(size: 20, weight: .bold))
                        .padding(.top, 10)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)

                    // Time Displays
                    Text(totalTime)
                        .font(.system(size: 30, weight: .bold))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .padding(.top, 10)
                    
                    Text("Current Lap: \(currentLap)")
                        .font(.system(size: 18))
                        .padding(.top, 10)
                    
                    Text("Best Lap: \(bestLap)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.red)
                        .padding(.top, 10)

                    // Control Buttons
                    HStack {
                        Button(action: {
                            if isRunning {
                                stopStopwatch()
                            } else {
                                startStopwatch()
                            }
                        }) {
                            Text(isRunning ? "Stop" : "Start")
                                .frame(width: 114, height: 40)
                                .background(isRunning ? Color.red : Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }

                        Button(action: {
                            showResetOptions = true
                        }) {
                            Text("Reset")
                                .frame(width: 114, height: 40)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.top, 10)

                    // Lap/Sector Buttons
                    HStack {
                        Button(action: addLap) {
                            Text("Lap")
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }

                        Button(action: addSector) {
                            Text("Sector")
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.top, 10)

                    // Lap/Sector List
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            if !sectorTimes.isEmpty && !sectorTimes[0].isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Current Lap Sectors")
                                        .font(.system(size: 16, weight: .bold))
                                        .padding(.vertical, 4)

                                    ForEach(sectorTimes[0], id: \.self) { sectorTime in
                                        Text(sectorTime)
                                            .font(.system(size: 14))
                                            .padding(.leading, 16)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }

                            ForEach(lapTimes.indices, id: \.self) { index in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(lapTimes[index])
                                        .font(.system(size: 16, weight: .bold))
                                        .padding(.vertical, 4)

                                    if sectorTimes.count > index + 1 {
                                        ForEach(sectorTimes[index + 1], id: \.self) { sectorTime in
                                            Text(sectorTime)
                                                .font(.system(size: 14))
                                                .padding(.leading, 16)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.bottom, 60)
                    }
                }
                .padding()
                
                // Floating Menu Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showMenu = true
                        }) {
                            Image(systemName: "ellipsis.circle")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(Color.blue))
                                .shadow(radius: 5)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
                
                if isUploading {
                    ProgressView("Uploading session...")
                        .padding()
                        .background(Color.gray.opacity(0.8))
                        .cornerRadius(10)
                }
            }
            .navigationBarHidden(true)
            .actionSheet(isPresented: $showMenu) {
                ActionSheet(
                    title: Text("Menu"),
                    buttons: [
                        .default(Text("Analytics"), action: {
                            showAnalytics = true
                            showMenu = false
                        }),
                        .default(Text("Map"), action: {
                            showMenu = false
                        }),
                        .default(Text(locationManager.isGPSEnabled ? "GPS Off" : "GPS On"),
                                 action: {
                            locationManager.toggleGPS()
                            showMenu = false
                        }),
                        .default(Text("Compare"), action: {
                            showComparison = true
                            showMenu = false
                        }),
                        .default(Text("History"), action: {
                            showHistory = true
                            showMenu = false
                        }),
                        .default(Text("Web Sessions"), action: {
                            if let url = URL(string: "https://moto.webhop.me/") {
                                UIApplication.shared.open(url)
                            }
                            showMenu = false
                        }),
                        .default(Text("Set Username"), action: {
                            showUsernameDialog = true
                            showMenu = false
                        }),
                        .default(Text("Live Session"), action: {
                            showLiveSessionOptions = true
                            showMenu = false
                        }),
                        .cancel {
                            showMenu = false
                        }
                    ]
                )
            }
            .actionSheet(isPresented: $showResetOptions) {
                ActionSheet(
                    title: Text("Reset Options"),
                    message: Text("Choose an option"),
                    buttons: [
                        .default(Text("Save and Reset"), action: {
                            isUploading = true
                            saveSession()
                            uploadToFlaskServer { success, message in
                                DispatchQueue.main.async {
                                    isUploading = false
                                    uploadMessage = message
                                    showUploadAlert = true
                                    if success {
                                        resetStopwatch()
                                    }
                                }
                            }
                            showResetOptions = false
                        }),
                        .default(Text("Save Only"), action: {
                            saveSession()
                            showResetOptions = false
                        }),
                        .destructive(Text("Reset Without Saving"), action: {
                            resetStopwatch()
                            showResetOptions = false
                        }),
                        .cancel {
                            showResetOptions = false
                        }
                    ]
                )
            }
            .actionSheet(isPresented: $showLiveSessionOptions) {
                ActionSheet(
                    title: Text("Live Session"),
                    message: Text("Status: \(liveSessionStatus)"),
                    buttons: [
                        .default(Text(isLiveSessionActive ? "Stop Live Session" : "Start Live Session"), action: {
                            toggleLiveSession()
                            showLiveSessionOptions = false
                        }),
                        .default(Text("Auto Start: \(autoStartLiveSession ? "ON" : "OFF")"), action: {
                            toggleAutoStart()
                            showLiveSessionOptions = false
                        }),
                        .cancel {
                            showLiveSessionOptions = false
                        }
                    ]
                )
            }
            .alert("Set Username", isPresented: $showUsernameDialog, actions: {
                TextField("Username", text: $username)
                Button("Save", action: saveUsername)
                Button("Cancel", role: .cancel) {}
            })
            .alert("Upload Status", isPresented: $showUploadAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(uploadMessage)
            }
            .sheet(isPresented: $showAnalytics) {
                LocationAnalyticsView(sessions: $sessions, saveSessions: saveSessions)
            }
            .sheet(isPresented: $showComparison) {
                SessionSelectionView(sessions: $sessions, selectedSessions: $selectedSessions)
            }
            .sheet(isPresented: $showComparisonResults) {
                CompareView(sessions: $sessions, selectedSessions: $selectedSessions)
            }
            .sheet(isPresented: $showHistory) {
                HistoryView(sessions: $sessions)
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear {
            if FirebaseApp.app() == nil {
                FirebaseApp.configure()
            }
            checkAutoStart()
            sessions = loadSessions()
        }
        .onDisappear {
            if isLiveSessionActive {
                stopLiveSession()
            }
        }
    }

    // MARK: - Stopwatch Methods
    private func startStopwatch() {
        if !isRunning {
            isRunning = true
            startTime = Date()
            lapStartTime = Date()
            sectorStartTime = Date()
            timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
                updateTime()
            }
        }
    }
    
    private func stopStopwatch() {
        isRunning = false
        timer?.invalidate()
    }
    
    private func resetStopwatch() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        startTime = Date()
        lapStartTime = Date()
        sectorStartTime = Date()
        totalTime = "00:00:00"
        currentLap = "00:00:00"
        bestLap = "00:00:00"
        
        lapTimes.removeAll()
        sectorTimes.removeAll()
        
        bestLapTime = .infinity
        lapCount = 0
        sectorCount = 0
        isFirstLap = true
        
        updateTime()
    }
    
    private func updateTime() {
        let currentTime = Date().timeIntervalSince(startTime)
        let lapTime = Date().timeIntervalSince(lapStartTime)
        totalTime = formatTime(currentTime)
        currentLap = formatTime(lapTime)
        
        if isLiveSessionActive {
            updateLiveSession()
        }
    }
    
    private func addLap() {
        if isRunning {
            let lapTime = Date().timeIntervalSince(lapStartTime)
            if lapTime < bestLapTime {
                bestLapTime = lapTime
                bestLap = formatTime(bestLapTime)
            }
            lapCount += 1
            lapTimes.insert("Lap \(lapCount): \(formatTime(lapTime))", at: 0)
            sectorTimes.insert([], at: 0)
            lapStartTime = Date()
            sectorStartTime = Date()
            sectorCount = 0
        }
    }
    
    private func addSector() {
        if isRunning {
            if sectorTimes.isEmpty {
                sectorTimes.append([])
            }
            
            let sectorTime = Date().timeIntervalSince(sectorStartTime)
            sectorCount += 1
            sectorTimes[0].insert("Sector \(sectorCount): \(formatTime(sectorTime))", at: 0)
            sectorStartTime = Date()
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d:%02d", minutes, seconds, milliseconds)
    }

    // MARK: - Session Management
    private func uploadToFlaskServer(completion: @escaping (Bool, String) -> Void) {
        let sessionData: [String: Any] = [
            "session": [
                "date": Date().timeIntervalSince1970,
                "fastest_lap": bestLap,
                "slowest_lap": lapTimes.map { $0.components(separatedBy: ": ").last ?? "00:00:00" }.max() ?? "00:00:00",
                "average_lap": calculateAverageLap(),
                "consistency": calculateConsistency(),
                "total_time": totalTime,
                "username": username.isEmpty ? "iOS User" : username,
                "device_type": "iOS"
            ],
            "laps": lapTimes.enumerated().map { index, lap in
                let time = lap.components(separatedBy: ": ").last ?? "00:00:00"
                let sectors = sectorTimes.count > index ? sectorTimes[index] : []
                return [
                    "lap_number": index + 1,
                    "lap_time": time,
                    "sectors": sectors
                ]
            }
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: sessionData) else {
            completion(false, "Failed to encode session data")
            return
        }
        
        guard let url = URL(string: "https://moto.webhop.me/upload") else {
            completion(false, "Invalid server URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, "Upload failed: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false, "Invalid server response")
                return
            }
            
            if httpResponse.statusCode == 200 {
                completion(true, "Session uploaded successfully!")
            } else {
                completion(false, "Server error: \(httpResponse.statusCode)")
            }
        }.resume()
    }
    
    private func saveSession() {
        guard !lapTimes.isEmpty else { return }
        
        let fastestLap = bestLap
        let slowestLap = lapTimes.map { $0.components(separatedBy: ": ").last ?? "00:00:00" }.max() ?? "00:00:00"
        let averageLap = calculateAverageLap()
        let consistency = calculateConsistency()
        let currentTotalTime = totalTime
        let location = locationManager.userLocation?.coordinate
        
        if let location = location {
            let geocoder = CLGeocoder()
            let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
            
            geocoder.reverseGeocodeLocation(clLocation) { placemarks, error in
                let cityName = placemarks?.first?.locality
                
                let session = LocationSession(
                    id: UUID(),
                    date: Date(),
                    fastestLap: fastestLap,
                    slowestLap: slowestLap,
                    averageLap: averageLap,
                    consistency: consistency,
                    lapTimes: lapTimes,
                    sectorTimes: sectorTimes,
                    location: cityName,
                    totalTime: currentTotalTime
                )
                
                self.sessions.append(session)
                self.saveSessions(self.sessions)
            }
        } else {
            let session = LocationSession(
                id: UUID(),
                date: Date(),
                fastestLap: fastestLap,
                slowestLap: slowestLap,
                averageLap: averageLap,
                consistency: consistency,
                lapTimes: lapTimes,
                sectorTimes: sectorTimes,
                location: nil,
                totalTime: currentTotalTime
            )
            
            self.sessions.append(session)
            self.saveSessions(self.sessions)
        }
    }
    
    private func calculateAverageLap() -> String {
        guard !lapTimes.isEmpty else { return "00:00:00" }
        
        let totalLapTime = lapTimes.reduce(0) { result, lapTime in
            let timeString = lapTime.components(separatedBy: ": ").last ?? "00:00:00"
            let components = timeString.components(separatedBy: ":")
            let minutes = Int(components[0]) ?? 0
            let seconds = Int(components[1]) ?? 0
            let milliseconds = Int(components[2]) ?? 0
            return result + TimeInterval(minutes * 60 + seconds) + TimeInterval(milliseconds) / 100
        }
        
        let averageLapTime = totalLapTime / Double(lapTimes.count)
        return formatTime(averageLapTime)
    }
    
    private func calculateConsistency() -> String {
        guard lapTimes.count > 1 else { return "N/A" }
        
        let lapTimesInSeconds = lapTimes.map { lapTime in
            let timeString = lapTime.components(separatedBy: ": ").last ?? "00:00:00"
            let components = timeString.components(separatedBy: ":")
            let minutes = Int(components[0]) ?? 0
            let seconds = Int(components[1]) ?? 0
            let milliseconds = Int(components[2]) ?? 0
            return TimeInterval(minutes * 60 + seconds) + TimeInterval(milliseconds) / 100
        }
        
        let averageLapTime = lapTimesInSeconds.reduce(0, +) / Double(lapTimes.count)
        let variance = lapTimesInSeconds.reduce(0) { result, lapTime in
            result + pow(lapTime - averageLapTime, 2)
        } / Double(lapTimes.count)
        
        let standardDeviation = sqrt(variance)
        let referenceStandardDeviation: TimeInterval = 7.0
        let consistencyPercentage = 100 * (1 - (standardDeviation / referenceStandardDeviation))
        let clampedConsistency = max(1, min(100, consistencyPercentage))
        
        return String(format: "%.0f%%", clampedConsistency)
    }
    
    private func saveSessions(_ sessions: [LocationSession]) {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: "savedSessions")
        }
    }
    
    private func loadSessions() -> [LocationSession] {
        if let data = UserDefaults.standard.data(forKey: "savedSessions"),
           let decoded = try? JSONDecoder().decode([LocationSession].self, from: data) {
            return decoded
        }
        return []
    }
    
    // MARK: - Live Session Methods
    private func toggleLiveSession() {
        if isLiveSessionActive {
            stopLiveSession()
            liveSessionStatus = "Not Active"
        } else {
            startLiveSession()
            liveSessionStatus = "Active"
        }
    }
    
    private func startLiveSession() {
        guard !username.isEmpty else {
            showAlert(title: "Error", message: "Please set a username first")
            return
        }
        
        let db = Database.database().reference()
        let sessionData: [String: Any] = [
            "start_time": ServerValue.timestamp(),
            "status": "active",
            "username": username,
            "device": "iOS",
            "current_lap": currentLap,
            "best_lap": bestLap,
            "location": [
                "latitude": locationManager.userLocation?.coordinate.latitude ?? 0,
                "longitude": locationManager.userLocation?.coordinate.longitude ?? 0
            ]
        ]
        
        liveSessionRef = db.child("live_sessions").child(username)
        liveSessionRef?.setValue(sessionData)
        isLiveSessionActive = true
        
        // Update every 5 seconds
        liveSessionTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            updateLiveSession()
        }
    }
    
    private func updateLiveSession() {
        guard isLiveSessionActive, let ref = liveSessionRef else { return }
        
        let updateData: [String: Any] = [
            "current_lap": currentLap,
            "best_lap": bestLap,
            "last_update": ServerValue.timestamp(),
            "location": [
                "latitude": locationManager.userLocation?.coordinate.latitude ?? 0,
                "longitude": locationManager.userLocation?.coordinate.longitude ?? 0
            ]
        ]
        
        ref.updateChildValues(updateData)
    }
    
    private func stopLiveSession() {
        guard let ref = liveSessionRef else { return }
        
        let endData: [String: Any] = [
            "status": "inactive",
            "end_time": ServerValue.timestamp()
        ]
        
        ref.updateChildValues(endData)
        isLiveSessionActive = false
        liveSessionRef = nil
        liveSessionTimer?.invalidate()
    }
    
    private func toggleAutoStart() {
        autoStartLiveSession.toggle()
        UserDefaults.standard.set(autoStartLiveSession, forKey: "autoStartLiveSession")
        showAlert(title: "Auto Start", message: autoStartLiveSession ? "Enabled - Will auto-start when app opens" : "Disabled")
    }
    
    private func checkAutoStart() {
        if autoStartLiveSession && !username.isEmpty {
            startLiveSession()
        }
    }
    
    private func saveUsername() {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUsername.isEmpty else {
            showAlert(title: "Error", message: "Username cannot be empty")
            return
        }
        
        UserDefaults.standard.set(trimmedUsername, forKey: "username")
        username = trimmedUsername
        
        if isLiveSessionActive {
            liveSessionRef?.updateChildValues(["username": trimmedUsername])
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
