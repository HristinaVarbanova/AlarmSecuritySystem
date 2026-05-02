import SwiftUI
import WebKit

struct LiveCameraView: View {
    private let cameraURL = URL(string: "http://192.168.100.47:81/stream")!

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.white,
                    Color.blue.opacity(0.10),
                    Color.yellow.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            WebView(url: cameraURL)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .padding()
        }
        .navigationTitle("Live Camera")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.load(URLRequest(url: url))
    }
}
