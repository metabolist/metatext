// Copyright © 2020 Metabolist. All rights reserved.

import SafariServices
import UIKit
import ViewModels

extension UIViewController {
    func present(alertItem: AlertItem) {
        let alertController = UIAlertController(
            title: nil,
            message: alertItem.error.localizedDescription,
            preferredStyle: .alert)

        let okAction = UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default) { _ in }

        alertController.addAction(okAction)

        present(alertController, animated: true)
    }

    #if !IS_SHARE_EXTENSION
    func open(url: URL, identityContext: IdentityContext) {
        func openWithRegardToBrowserSetting(url: URL) {
            if identityContext.appPreferences.openLinksInDefaultBrowser || !url.isHTTPURL {
                UIApplication.shared.open(url)
            } else {
                present(SFSafariViewController(url: url), animated: true)
            }
        }

        if identityContext.appPreferences.useUniversalLinks {
            UIApplication.shared.open(url, options: [.universalLinksOnly: true]) { success in
                if !success {
                    openWithRegardToBrowserSetting(url: url)
                }
            }
        } else {
            openWithRegardToBrowserSetting(url: url)
        }
    }
    #endif
}
