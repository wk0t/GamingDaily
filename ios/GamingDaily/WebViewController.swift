import UIKit
import WebKit

// Displays the web UI (the same as the Android app) in a WKWebView and provides
// the "AndroidBridge" the page expects: CORS-free network requests, version,
// opening links and sharing. Text-to-speech falls back to the web API (Web Speech).
class WebViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {

    private var webView: WKWebView!

    override func loadView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        let controller = WKUserContentController()
        controller.add(self, name: "bridge")

        let version = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.1.0"
        // The shim is injected BEFORE the document loads: the page sees an
        // AndroidBridge just like on Android. fetchUrl/openUrl/share go through the
        // native message handler; appVersion is synchronous (injected value).
        let shim = """
        window.AndroidBridge = {
          fetchUrl: function(u, id){ window.webkit.messageHandlers.bridge.postMessage({fn:'fetchUrl', url:u, id:String(id)}); },
          appVersion: function(){ return '\(version)'; },
          openUrl: function(u){ window.webkit.messageHandlers.bridge.postMessage({fn:'openUrl', url:u}); },
          share: function(t){ window.webkit.messageHandlers.bridge.postMessage({fn:'share', text:t}); },
          saveCache: function(d){}, loadCache: function(){ return ''; }
        };
        """
        controller.addUserScript(WKUserScript(source: shim, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        config.userContentController = controller

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = self
        wv.uiDelegate = self
        wv.allowsBackForwardNavigationGestures = false
        self.webView = wv
        self.view = wv
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }

    // MARK: - JS -> native bridge
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let fn = body["fn"] as? String else { return }
        switch fn {
        case "fetchUrl":
            guard let urlStr = body["url"] as? String,
                  let idStr = body["id"] as? String,
                  let url = URL(string: urlStr) else { return }
            fetchUrl(url, id: idStr)
        case "openUrl":
            if let urlStr = body["url"] as? String, let url = URL(string: urlStr) {
                UIApplication.shared.open(url)
            }
        case "share":
            if let text = body["text"] as? String {
                let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                av.popoverPresentationController?.sourceView = self.view
                present(av, animated: true)
            }
        default:
            break
        }
    }

    private func fetchUrl(_ url: URL, id: String) {
        var req = URLRequest(url: url)
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 15
        URLSession.shared.dataTask(with: req) { [weak self] data, response, _ in
            var b64 = ""
            if let d = data {
                var encoding = String.Encoding.utf8
                if let http = response as? HTTPURLResponse,
                   let ct = http.value(forHTTPHeaderField: "Content-Type"),
                   let range = ct.range(of: "charset=", options: .caseInsensitive) {
                    let name = ct[range.upperBound...].prefix { $0.isLetter || $0.isNumber || $0 == "-" }
                    let cf = CFStringConvertIANACharSetNameToEncoding(String(name) as CFString)
                    if cf != kCFStringEncodingInvalidId {
                        encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cf))
                    }
                }
                let text = String(data: d, encoding: encoding) ?? String(data: d, encoding: .utf8) ?? ""
                b64 = Data(text.utf8).base64EncodedString()
            }
            let payload = b64
            DispatchQueue.main.async {
                self?.webView.evaluateJavaScript("onFetchDone(\(id), '\(payload)')", completionHandler: nil)
            }
        }.resume()
    }

    // MARK: - External links (target=_blank / taps to a site) -> Safari
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url,
           url.scheme == "http" || url.scheme == "https" {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    // window.open(...) -> Safari
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            UIApplication.shared.open(url)
        }
        return nil
    }
}
