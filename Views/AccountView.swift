// Copyright © 2020 Metabolist. All rights reserved.

import Kingfisher
import UIKit

class AccountView: UIView {
    let avatarImageView = AnimatedImageView()
    let noteTextView = TouchFallthroughTextView()

    private var accountConfiguration: AccountContentConfiguration

    init(configuration: AccountContentConfiguration) {
        self.accountConfiguration = configuration

        super.init(frame: .zero)

        initialSetup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AccountView: UIContentView {
    var configuration: UIContentConfiguration {
        get { accountConfiguration }
        set {
            guard let accountConfiguration = newValue as? AccountContentConfiguration else { return }

            self.accountConfiguration = accountConfiguration

            avatarImageView.kf.cancelDownloadTask()
            applyAccountConfiguration()
        }
    }
}

private extension AccountView {
    func initialSetup() {
        let baseStackView = UIStackView()

        addSubview(baseStackView)
        baseStackView.translatesAutoresizingMaskIntoConstraints = false
        baseStackView.addArrangedSubview(avatarImageView)
        baseStackView.addArrangedSubview(noteTextView)
        noteTextView.isScrollEnabled = false

        NSLayoutConstraint.activate([
            baseStackView.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
            baseStackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            baseStackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            baseStackView.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor)
        ])

        applyAccountConfiguration()
    }

    func applyAccountConfiguration() {
        avatarImageView.kf.setImage(with: accountConfiguration.viewModel.avatarURL)
        noteTextView.attributedText = accountConfiguration.viewModel.note
    }
}
