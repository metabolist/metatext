// Copyright © 2020 Metabolist. All rights reserved.

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
}
