import SwiftUI
import MapKit
import CoreLocation
import Firebase
import FirebaseDatabase

// Custom Button Implementation that always works
struct GuaranteedButton: View {
    let action: () -> Void
    let label: Text
    let backgroundColor: Color
    let disabled: Bool
    let fixedWidth: CGFloat?
    
    @State private var isPressed = false
    
    init(action: @escaping () -> Void, label: Text, backgroundColor: Color, disabled: Bool = false, fixedWidth: CGFloat? = nil) {
        self.action = action
        self.label = label
        self.backgroundColor = backgroundColor
        self.disabled = disabled
        self.fixedWidth = fixedWidth
    }
    
    var body: some View {
        let actualColor = disabled ? Color.gray : backgroundColor
        
        return label
            .frame(width: fixedWidth, height: 40)
            .frame(maxWidth: fixedWidth == nil ? .infinity : nil)
            .background(isPressed ? actualColor.opacity(0.7) : actualColor)
            .foregroundColor(.white)
            .cornerRadius(8)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !disabled {
                            withAnimation {
                                isPressed = true
                            }
                        }
                    }
                    .onEnded { _ in
                        withAnimation {
                            isPressed = false
                        }
                        if !disabled {
                            action()
                        }
                    }
            )
    }
}

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
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
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
        ZStack {
            NavigationView {
                ZStack {
                    Color(.systemBackground)
                        .edgesIgnoringSafeArea(.all)
                    
                    // Main Content
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
                            GuaranteedButton(
                                action: {
                                    if isRunning {
                                        stopStopwatch()
                                    } else {
                                        startStopwatch()
                                    }
                                },
                                label: Text(isRunning ? "Stop" : "Start"),
                                backgroundColor: isRunning ? .red : .green,
                                fixedWidth: 114
                            )
                            
                            GuaranteedButton(
                                action: { showResetOptions = true },
                                label: Text("Reset"),
                                backgroundColor: .blue,
                                fixedWidth: 114
                            )
                        }
                        .padding(.top, 10)

                        // Lap/Sector Buttons
                        HStack {
                            GuaranteedButton(
                                action: addLap,
                                label: Text("Lap"),
                                backgroundColor: .orange,
                                disabled: !isRunning
                            )
                            
                            GuaranteedButton(
                                action: addSector,
                                label: Text("Sector"),
                                backgroundColor: .purple,
                                disabled: !isRunning
                            )
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
                            GuaranteedButton(
                                action: { showMenu = true },
                                label: Text("").hidden(),
                                backgroundColor: .blue,
                                fixedWidth: 50
                            )
                            .overlay(
                                Image(systemName: "ellipsis.circle")
                                    .font(.title)
                                    .foregroundColor(.white)
                            )
                            .frame(width: 50, height: 50)
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                    }
                    .zIndex(100)
                    
                    if isUploading {
                        ProgressView("Uploading session...")
                            .padding()
                            .background(Color.gray.opacity(0.8))
                            .cornerRadius(10)
                    }
                }
                .navigationBarHidden(true)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .actionSheet(isPresented: $showMenu) {
            ActionSheet(
                title: Text("Menu"),
                buttons: [
                    .default(Text("Analytics"), action: {
                        showAnalytics = true
                    }),
                    .default(Text("Map"), action: {
                        // Map action
                    }),
                    .default(Text(locationManager.isGPSEnabled ? "GPS Off" : "GPS On"), action: {
                        locationManager.toggleGPS()
                    }),
                    .default(Text("Compare"), action: {
                        showComparison = true
                    }),
                    .default(Text("History"), action: {
                        showHistory = true
                    }),
                    .default(Text("Web Sessions"), action: {
                        if let url = URL(string: "https://moto.webhop.me/") {
                            UIApplication.shared.open(url)
                        }
                    }),
                    .default(Text("Set Username"), action: {
                        showUsernameDialog = true
                    }),
                    .default(Text("Live Session"), action: {
                        showLiveSessionOptions = true
                    }),
                    .cancel()
                ]
            )
        }
        .actionSheet(isPresented: $showResetOptions) {
            ActionSheet(
                title: Text("Reset Options"),
                message: Text("Save your session before resetting?"),
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
                    }),
                    .default(Text("Save Only"), action: {
                        saveSession()
                    }),
                    .destructive(Text("Reset Without Saving"), action: {
                        resetStopwatch()
                    }),
                    .cancel()
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
                    }),
                    .default(Text("Auto Start: \(autoStartLiveSession ? "ON" : "OFF")"), action: {
                        toggleAutoStart()
                    }),
                    .cancel()
                ]
            )
        }
        .alert("Set Username", isPresented: $showUsernameDialog) {
            TextField("Username", text: $username)
            Button("Save", action: saveUsername)
            Button("Cancel", role: .cancel) {}
        }
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
        guard !isRunning else { return }
        
        isRunning = true
        startTime = Date()
        lapStartTime = Date()
        sectorStartTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            guard self.isRunning else { return }
            self.updateTime()
        }
    }
    
    private func stopStopwatch() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resetStopwatch() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        totalTime = "00:00:00"
        currentLap = "00:00:00"
        bestLap = "00:00:00"
        lapTimes.removeAll()
        sectorTimes.removeAll()
        bestLapTime = .infinity
        lapCount = 0
        sectorCount = 0
        isFirstLap = true
        
        // Reset all timestamps
        let now = Date()
        startTime = now
        lapStartTime = now
        sectorStartTime = now
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
    
    private func addSector() {
        if sectorTimes.isEmpty {
            sectorTimes.append([])
        }
        
        let sectorTime = Date().timeIntervalSince(sectorStartTime)
        sectorCount += 1
        sectorTimes[0].insert("Sector \(sectorCount): \(formatTime(sectorTime))", at: 0)
        sectorStartTime = Date()
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d:%02d", minutes, seconds, milliseconds)
    }

    // [Keep all your other methods exactly the same...]
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
