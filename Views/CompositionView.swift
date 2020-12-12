// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Kingfisher
import UIKit

class CompositionView: UIView {
    let avatarImageView = UIImageView()
    let textView = UITextView()

    private var compositionConfiguration: CompositionContentConfiguration
    private var cancellables = Set<AnyCancellable>()

    init(configuration: CompositionContentConfiguration) {
        self.compositionConfiguration = configuration

        super.init(frame: .zero)

        initialSetup()
        applyCompositionConfiguration()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CompositionView: UIContentView {
    var configuration: UIContentConfiguration {
        get { compositionConfiguration }
        set {
            guard let compositionConfiguration = newValue as? CompositionContentConfiguration else { return }

            self.compositionConfiguration = compositionConfiguration

            applyCompositionConfiguration()
        }
    }
}

private extension CompositionView {
    func initialSetup() {
        addSubview(avatarImageView)
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.layer.cornerRadius = .avatarDimension / 2
        avatarImageView.clipsToBounds = true

        let stackView = UIStackView()

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical

        stackView.addArrangedSubview(textView)
        textView.isScrollEnabled = false
        textView.adjustsFontForContentSizeCategory = true
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textContainer.lineFragmentPadding = 0

        let constraints = [
            avatarImageView.heightAnchor.constraint(equalToConstant: .avatarDimension),
            avatarImageView.widthAnchor.constraint(equalToConstant: .avatarDimension),
            avatarImageView.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            avatarImageView.bottomAnchor.constraint(lessThanOrEqualTo: readableContentGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: .defaultSpacing),
            stackView.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor)
        ]

        for constraint in constraints {
            constraint.priority = .justBelowMax
        }

        NSLayoutConstraint.activate(constraints)

        compositionConfiguration.viewModel.$identification.map(\.identity.image)
            .sink { [weak self] in self?.avatarImageView.kf.setImage(with: $0) }
            .store(in: &cancellables)
    }

    func applyCompositionConfiguration() {

    }
}
