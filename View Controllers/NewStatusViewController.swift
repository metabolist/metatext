// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

class NewStatusViewController: UIViewController {
    private let viewModel: NewStatusViewModel

    init(viewModel: NewStatusViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = .init(
            systemItem: .close,
            primaryAction: UIAction { [weak self] _ in self?.extensionContext?.completeRequest(returningItems: nil) })
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)

        parent?.navigationItem.leftBarButtonItem = .init(
            systemItem: .close,
            primaryAction: UIAction { [weak self] _ in self?.presentingViewController?.dismiss(animated: true) })
    }
}
