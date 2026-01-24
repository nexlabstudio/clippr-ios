import SwiftUI
import ClipprSDK

@main
struct ExampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    Clippr.handleUniversalLink(url)
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Clippr.initialize(
            apiKey: "clippr_live_your_api_key_here",
            debug: true
        )
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        return Clippr.handleUniversalLink(userActivity)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = DeepLinkViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                StatusCard(viewModel: viewModel)

                if let link = viewModel.currentLink {
                    DeepLinkCard(link: link)
                }

                ActionButtons(viewModel: viewModel)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Clippr Demo")
            .task {
                await viewModel.checkForInitialLink()
            }
        }
    }
}

@MainActor
class DeepLinkViewModel: ObservableObject {
    @Published var currentLink: ClipprLink?
    @Published var status: String = "Initializing..."
    @Published var eventsSent: Int = 0
    
    init() {
        Clippr.onLink = { [weak self] link in
            self?.handleLink(link, source: "onLink")
        }
    }
    
    func checkForInitialLink() async {
        status = "Checking for deep link..."
        
        if let link = await Clippr.getInitialLink() {
            handleLink(link, source: "getInitialLink")
        } else {
            status = "No deep link found"
        }
    }
    
    private func handleLink(_ link: ClipprLink, source: String) {
        currentLink = link
        status = "Link received via \(source)"
        
        // In a real app, you would navigate based on the path
        print("📱 Deep Link Received:")
        print("   Path: \(link.path)")
        print("   Match Type: \(link.matchType)")
        print("   Confidence: \(link.confidence ?? 0)")
        print("   Campaign: \(link.attribution?.campaign ?? "none")")
    }
    
    func trackTestEvent() async {
        do {
            try await Clippr.track("test_event", params: [
                "button": "test_button",
                "timestamp": Date().timeIntervalSince1970
            ])
            eventsSent += 1
            status = "Event tracked successfully!"
        } catch {
            status = "Error: \(error.localizedDescription)"
        }
    }
    
    func trackPurchase() async {
        do {
            try await Clippr.trackRevenue(
                "purchase",
                revenue: 9.99,
                currency: "USD",
                params: ["product_id": "demo_product"]
            )
            eventsSent += 1
            status = "Purchase tracked!"
        } catch {
            status = "Error: \(error.localizedDescription)"
        }
    }
}

struct StatusCard: View {
    @ObservedObject var viewModel: DeepLinkViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Status", systemImage: "info.circle")
                .font(.headline)
            
            Text(viewModel.status)
                .foregroundColor(.secondary)
            
            Text("Events sent: \(viewModel.eventsSent)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DeepLinkCard: View {
    let link: ClipprLink
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Deep Link", systemImage: "link")
                .font(.headline)
            
            InfoRow(label: "Path", value: link.path)
            InfoRow(label: "Match Type", value: link.matchType.rawValue)
            
            if let confidence = link.confidence {
                InfoRow(label: "Confidence", value: String(format: "%.1f%%", confidence * 100))
            }
            
            if let attribution = link.attribution {
                Divider()
                Text("Attribution")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let campaign = attribution.campaign {
                    InfoRow(label: "Campaign", value: campaign)
                }
                if let source = attribution.source {
                    InfoRow(label: "Source", value: source)
                }
                if let medium = attribution.medium {
                    InfoRow(label: "Medium", value: medium)
                }
            }
            
            if let metadata = link.metadata, !metadata.isEmpty {
                Divider()
                Text("Metadata")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ForEach(Array(metadata.keys), id: \.self) { key in
                    InfoRow(label: key, value: "\(metadata[key]?.value ?? "")")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

struct ActionButtons: View {
    @ObservedObject var viewModel: DeepLinkViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await viewModel.trackTestEvent()
                }
            } label: {
                Label("Track Test Event", systemImage: "paperplane")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            
            Button {
                Task {
                    await viewModel.trackPurchase()
                }
            } label: {
                Label("Track Purchase ($9.99)", systemImage: "cart")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
}

#Preview {
    ContentView()
}
