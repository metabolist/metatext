// Copyright © 2022 Metabolist. All rights reserved.

import MobileCoreServices
import UIKit
import UniformTypeIdentifiers

/// Let the user open a URL that might be a Mastodon profile or post in Metatext.
/// Should activate for one or more web URLs, but will only do anything with the first..
class ActionExtensionViewController: UIViewController {
    /// Extensions aren't allowed to call `UIApplication.shared
    ///  and thus don't have direct access to its `openURL` method.
    /// `self.extensionContext?.open(<#T##URL: URL##URL#>)` only works for Today extensions.
    /// As a workaround, we find a parent responder that has an `openURL(_:)` method.
    /// This will be `UIApplication`. It's cursed, but it uses public APIs and works.
    /// See <https://liman.io/blog/open-url-share-extension-swiftui>.
    private func open(url: URL) {
        var responder: UIResponder? = self as UIResponder
        let selector = #selector(openURL(_:))
        while responder != nil {
            if responder!.responds(to: selector) && responder != self {
                responder!.perform(selector, with: url)
                return
            }
            responder = responder?.next
        }
    }

    /// Only exists so we can create a selector from it.
    @objc private func openURL(_ url: URL) {
        return
    }

    /// This extension has no actual UI, so we act on extension input items as soon as we load.
    override func viewDidLoad() {
        super.viewDidLoad()

        // Find the first URL or thing coerceable to a URL.
        for item in self.extensionContext!.inputItems as? [NSExtensionItem] ?? [] {
            for provider in item.attachments! where provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                _ = provider.loadObject(ofClass: URL.self) { (url, error) in
                    OperationQueue.main.addOperation {
                        if let error = error {
                            self.extensionContext!.cancelRequest(withError: error)
                        } else if let url = url {
                            // Create a `metatext:search?url=https…` URL from our web URL.
                            var urlBuilder = URLComponents()
                            urlBuilder.scheme = "metatext"
                            urlBuilder.path = "search"
                            urlBuilder.queryItems = [.init(name: "url", value: url.absoluteString)]
                            let metatextURL = urlBuilder.url!
                            self.open(url: metatextURL)
                            self.extensionContext!.completeRequest(returningItems: [])
                        } else {
                            // Should never happen. Return a generic not-found error.
                            self.extensionContext!.cancelRequest(withError: CocoaError(.fileNoSuchFile))
                        }
                    }
                }
                // We do not attempt to handle multiple URLs.
                return
            }
        }
        // No URLs. Return a generic not-found error.
        self.extensionContext!.cancelRequest(withError: CocoaError(.fileNoSuchFile))
    }
}
