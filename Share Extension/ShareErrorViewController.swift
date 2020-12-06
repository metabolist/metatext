// Copyright © 2020 Metabolist. All rights reserved.

import UIKit

class ShareErrorViewController: UIViewController {
    let error: Error

    init(error: Error) {
        self.error = error

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let label = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .callout)
        label.text = (error as? LocalizedError)?.errorDescription ?? NSLocalizedString("error", comment: "")

        navigationItem.leftBarButtonItem = .init(
            systemItem: .close,
            primaryAction: UIAction { [weak self] _ in self?.extensionContext?.completeRequest(returningItems: nil) })

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            label.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            label.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)
        ])
    }
}
