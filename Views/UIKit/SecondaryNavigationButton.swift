// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import Kingfisher
import UIKit
import ViewModels

final class SecondaryNavigationButton: UIBarButtonItem {
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: NavigationViewModel, rootViewModel: RootViewModel) {
        super.init()

        let button = UIButton(
            type: .custom,
            primaryAction: UIAction { _ in viewModel.presentingSecondaryNavigation = true })

        button.imageView?.contentMode = .scaleAspectFill
        button.layer.cornerRadius = .barButtonItemDimension / 2
        button.clipsToBounds = true

        customView = button

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: .barButtonItemDimension),
            button.heightAnchor.constraint(equalToConstant: .barButtonItemDimension)
        ])

        viewModel.identityContext.$identity.sink {
            button.kf.setImage(
                with: $0.image,
                for: .normal,
                placeholder: UIImage(systemName: "line.horizontal.3"))
        }
        .store(in: &cancellables)

        viewModel.$recentIdentities.sink { identities in
            button.menu = UIMenu(children: identities.map { identity in
                UIDeferredMenuElement { completion in
                    let action = UIAction(title: identity.handle) { _ in
                        rootViewModel.identitySelected(id: identity.id)
                    }

                    if let image = identity.image {
                        KingfisherManager.shared.retrieveImage(with: image) {
                            if case let .success(value) = $0 {
                                action.image = value.image
                            }

                            completion([action])
                        }
                    } else {
                        completion([action])
                    }
                }
            })
        }
        .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
