import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    let pages = [
        "Welcome to MX StopWatch GPS",
        "Track your laps and sectors with precision",
        "Visualize your GPS tracking on the map",
        "Compare your lap and sector times"
    ]
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Text(pages[index])
                        .font(.system(size: 24, weight: .bold))
                        .multilineTextAlignment(.center)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            
            Button(action: {
                if currentPage < pages.count - 1 {
                    currentPage += 1
                } else {
                    // Navigate to main content
                }
            }) {
                Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                    .frame(width: 200, height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}
