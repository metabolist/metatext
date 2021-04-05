// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import UIKit
import WebKit

final class InstancePickerViewController: UIViewController {
    private let selectionAction: (InstancePickerViewController, String) -> Void
    private let webView: WKWebView
    private let backButton: UIBarButtonItem
    private let forwardButton: UIBarButtonItem
    private var cancellables = Set<AnyCancellable>()

    init(selectionAction: @escaping (InstancePickerViewController, String) -> Void) {
        let webView = WKWebView()

        webView.allowsBackForwardNavigationGestures = true
        self.webView = webView
        self.selectionAction = selectionAction
        backButton = UIBarButtonItem(title: nil, image: UIImage(systemName: "chevron.backward"),
                                     primaryAction: UIAction {  _ in webView.goBack() })
        forwardButton = UIBarButtonItem(title: nil, image: UIImage(systemName: "chevron.forward"),
                                     primaryAction: UIAction {  _ in webView.goForward() })

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = webView
        webView.navigationDelegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .done,
            primaryAction: UIAction { [weak self] _ in self?.presentingViewController?.dismiss(animated: true) })
        navigationItem.rightBarButtonItems = [forwardButton, backButton]

        webView.publisher(for: \.canGoBack)
            .sink { [weak self] in self?.backButton.isEnabled = $0 }
            .store(in: &cancellables)

        webView.publisher(for: \.canGoForward)
            .sink { [weak self] in self?.forwardButton.isEnabled = $0 }
            .store(in: &cancellables)

        webView.publisher(for: \.title)
            .sink { [weak self] in self?.navigationItem.title = $0 }
            .store(in: &cancellables)

        webView.load(.init(url: Self.url))
    }
}

extension InstancePickerViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 preferences: WKWebpagePreferences,
                 decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        if webView.url?.host == "joinmastodon.org",
           let url = navigationAction.request.url,
           let host = url.host,
           host != "joinmastodon.org",
           url.pathComponents == ["/", "about"] {
            decisionHandler(.cancel, preferences)
            selectionAction(self, host)
        } else {
            decisionHandler(.allow, preferences)
        }
    }
}

private extension InstancePickerViewController {
    static let url = URL(string: "https://joinmastodon.org/communities")!
}
