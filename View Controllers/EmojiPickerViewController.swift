// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import UIKit
import ViewModels

final class EmojiPickerViewController: UIViewController {
    let searchBar = UISearchBar()

    private let viewModel: EmojiPickerViewModel
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: EmojiPickerViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let searchBar = UISearchBar()

        view.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.searchBarStyle = .minimal

        NSLayoutConstraint.activate([
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

//        print(UITextInputMode.activeInputModes.map(\.primaryLanguage))
        print(Locale.availableIdentifiers)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard let containerView = popoverPresentationController?.containerView else { return }

        // gets the popover presentation controller's built-in visual effect view to actually show
        func setClear(view: UIView) {
            view.backgroundColor = .clear

            if view == self.view {
                return
            }

            for view in view.subviews {
                setClear(view: view)
            }
        }

        setClear(view: containerView)
    }
}
