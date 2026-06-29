//
//  ContentView.swift
//  PMBSA
//
//  Created by Chris Olivier on 27/06/2026.
//

import SwiftUI
import WebKit

struct ContentView: View {
    @State private var shouldReload = false
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var isLoading = false
    @State private var showQuickLinks = false
    @State private var webViewStore = WebViewStore()
    @State private var loadingTask: Task<Void, Never>?
    @State private var selectedMedicalAidURL: String?
    @State private var showingInAppBrowser = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main WebView
                WebView(
                    url: URL(string: "https://ampedlifepmbsa.netlify.app"),
                    reload: $shouldReload,
                    canGoBack: $canGoBack,
                    canGoForward: $canGoForward,
                    isLoading: $isLoading,
                    store: webViewStore
                )
                .ignoresSafeArea(edges: .bottom)
                
                // Loading indicator
                if isLoading {
                    VStack {
                        Spacer()
                        HStack {
                            ProgressView()
                                .progressViewStyle(.circular)
                            Text("Loading...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .padding(.bottom, 100)
                    }
                    .onAppear {
                        // Failsafe: Force stop loading after 10 seconds
                        loadingTask?.cancel()
                        loadingTask = Task {
                            try? await Task.sleep(nanoseconds: 10_000_000_000)
                            if !Task.isCancelled {
                                isLoading = false
                            }
                        }
                    }
                    .onDisappear {
                        loadingTask?.cancel()
                    }
                }
            }
            .navigationTitle("PMB Prosthetics SA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Bottom toolbar with all buttons
                ToolbarItemGroup(placement: .bottomBar) {
                    // Back button
                    Button {
                        webViewStore.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(!canGoBack)
                    
                    // Forward button
                    Button {
                        webViewStore.goForward()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(!canGoForward)
                    
                    Spacer()
                    
                    // Quick Links Menu
                    Button {
                        showQuickLinks = true
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                    
                    Spacer()
                    
                    // Share button
                    Button {
                        shareApp()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Spacer()
                    
                    // Reload button
                    Button {
                        shouldReload.toggle()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .sheet(isPresented: $showQuickLinks) {
                QuickLinksView(
                    webViewStore: webViewStore,
                    isPresented: $showQuickLinks,
                    selectedURL: $selectedMedicalAidURL,
                    showingInAppBrowser: $showingInAppBrowser
                )
            }
            .sheet(isPresented: $showingInAppBrowser) {
                if let urlString = selectedMedicalAidURL {
                    InAppBrowserView(urlString: urlString, isPresented: $showingInAppBrowser)
                }
            }
        }
    }
    
    // Share functionality
    private func shareApp() {
        guard let url = URL(string: "https://ampedlifepmbsa.netlify.app") else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: [
                "Check out this helpful PMB Prosthetics information for South African medical aids:",
                url
            ],
            applicationActivities: nil
        )
        
        // For iPad support
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            
            // Find the topmost view controller
            var topVC = rootVC
            while let presentedVC = topVC.presentedViewController {
                topVC = presentedVC
            }
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            topVC.present(activityVC, animated: true)
        }
    }
}

// Quick Links Sheet View
struct QuickLinksView: View {
    let webViewStore: WebViewStore
    @Binding var isPresented: Bool
    @Binding var selectedURL: String?
    @Binding var showingInAppBrowser: Bool
    
    // Define your medical aid schemes with their official websites
    let medicalAids = [
        MedicalAid(name: "Discovery Health", icon: "cross.case.fill", color: .green, url: "https://www.discovery.co.za"),
        MedicalAid(name: "Bonitas", icon: "heart.fill", color: .blue, url: "https://www.bonitas.co.za"),
        MedicalAid(name: "Fedhealth", icon: "cross.fill", color: .red, url: "https://www.fedhealth.co.za"),
        MedicalAid(name: "Momentum Health", icon: "bolt.heart.fill", color: .orange, url: "https://www.momentum.co.za/momentum/personal/products/medical-aid"),
        MedicalAid(name: "Bestmed", icon: "staroflife.fill", color: .purple, url: "https://www.bestmed.co.za"),
        MedicalAid(name: "Medshield", icon: "shield.fill", color: .cyan, url: "https://www.medshield.co.za"),
        MedicalAid(name: "GEMS", icon: "sparkles", color: .indigo, url: "https://www.gems.gov.za")
    ]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        webViewStore.loadURL("https://ampedlifepmbsa.netlify.app")
                        isPresented = false
                    } label: {
                        Label("Home", systemImage: "house.fill")
                    }
                }
                
                Section("Medical Aid Schemes") {
                    ForEach(medicalAids) { aid in
                        Button {
                            // Open directly in Safari (more reliable for external sites)
                            if let url = URL(string: aid.url) {
                                UIApplication.shared.open(url)
                            }
                            isPresented = false
                        } label: {
                            HStack {
                                Image(systemName: aid.icon)
                                    .foregroundStyle(aid.color)
                                    .frame(width: 30)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(aid.name)
                                        .foregroundStyle(.primary)
                                    Text("Open in Safari")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                Section("Support & Links") {
                    // Support email
                    Button {
                        let email = "chris@integratedlife.co.za"
                        let subject = "PMB App Support"
                        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        let urlString = "mailto:\(email)?subject=\(subjectEncoded)"
                        
                        if let emailURL = URL(string: urlString) {
                            UIApplication.shared.open(emailURL) { success in
                                if !success {
                                    print("Failed to open mail app")
                                }
                            }
                        }
                        isPresented = false
                    } label: {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 30)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Support")
                                    .foregroundStyle(.primary)
                                Text("chris@integratedlife.co.za")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Integrated Life website
                    Button {
                        if let url = URL(string: "https://integratedlife.co.za") {
                            UIApplication.shared.open(url)
                        }
                        isPresented = false
                    } label: {
                        HStack {
                            Image(systemName: "heart.text.square.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 30)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Integrated Life")
                                    .foregroundStyle(.primary)
                                Text("Open in Safari")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // AmpedLife website - opens YouTube channel
                    Button {
                        if let url = URL(string: "https://youtube.com/@theampedlife") {
                            UIApplication.shared.open(url)
                        }
                        isPresented = false
                    } label: {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundStyle(.orange)
                                .frame(width: 30)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("AmpedLife")
                                    .foregroundStyle(.primary)
                                Text("Open YouTube Channel")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Quick Links")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// In-App Browser View
struct InAppBrowserView: View {
    let urlString: String
    @Binding var isPresented: Bool
    @State private var isLoading = true
    @State private var webViewStore = WebViewStore()
    @State private var canGoBack = false
    @State private var canGoForward = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if let url = URL(string: urlString) {
                    WebView(
                        url: url,
                        reload: .constant(false),
                        canGoBack: $canGoBack,
                        canGoForward: $canGoForward,
                        isLoading: $isLoading,
                        store: webViewStore
                    )
                    .ignoresSafeArea(edges: .bottom)
                }
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Medical Aid Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        webViewStore.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(!canGoBack)
                    
                    Button {
                        webViewStore.goForward()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(!canGoForward)
                    
                    Spacer()
                    
                    Button {
                        webViewStore.reload()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    
                    Spacer()
                    
                    Button {
                        if let url = URL(string: urlString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "safari")
                    }
                }
            }
        }
    }
}

// Model for Medical Aid Schemes
struct MedicalAid: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let url: String
}

// WebView Store - manages WebView actions
@Observable
class WebViewStore {
    var webView: WKWebView?
    
    func goBack() {
        webView?.goBack()
    }
    
    func goForward() {
        webView?.goForward()
    }
    
    func reload() {
        webView?.reload()
    }
    
    func loadURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        webView?.load(URLRequest(url: url))
    }
}

// WebView component to display your website
struct WebView: UIViewRepresentable {
    let url: URL?
    @Binding var reload: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool
    var store: WebViewStore
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // Allow inline media playback (for videos)
        configuration.allowsInlineMediaPlayback = true
        
        // Enable JavaScript (modern way)
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        
        // Set the navigation delegate to handle link clicks
        webView.navigationDelegate = context.coordinator
        
        // Configure for better mobile experience
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        // Store reference to webView
        store.webView = webView
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Load the URL initially
        if webView.url == nil, let url = url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        // Handle reload when the reload state changes
        if reload != context.coordinator.lastReloadState {
            webView.reload()
            context.coordinator.lastReloadState = reload
        }
        
        // Update navigation state
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }
    
    // Create a Coordinator to handle navigation
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var lastReloadState: Bool = false
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        // Called when navigation starts
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }
        
        // Called when navigation finishes successfully
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
            }
            
            // JavaScript injection disabled - links should be added directly to the HTML instead
            // To make the banners clickable, add these to your HTML on Netlify:
            // Green banner: <a href="https://integratedlife.co.za">...</a>
            // Red banner: <a href="https://youtube.com/@theampedlife">...</a>
        }
        
        // Called when navigation fails
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
        
        // Called when provisional navigation fails
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
        
        // Called when content starts arriving
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
            }
        }
        
        // This method is called when a link is clicked
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            // Get the URL that was clicked
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            
            // Check if this is a link click (not the initial page load)
            if navigationAction.navigationType == .linkActivated {
                
                // List of domains that should open in Safari
                let externalDomains = [
                    "youtube.com",
                    "youtu.be",
                    "integratedlife.co.za",
                    "ilive.today"
                    // Add any other external sites here
                ]
                
                // Check if the link is to an external domain
                let shouldOpenExternally = externalDomains.contains { domain in
                    url.host?.contains(domain) ?? false
                }
                
                if shouldOpenExternally {
                    // Open in Safari
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
            }
            
            // Allow the navigation to happen in the WebView
            decisionHandler(.allow)
        }
    }
}

#Preview {
    ContentView()
}
