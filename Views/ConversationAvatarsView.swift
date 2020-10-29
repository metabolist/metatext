// Copyright © 2020 Metabolist. All rights reserved.

import Kingfisher
import UIKit
import ViewModels

final class ConversationAvatarsView: UIView {
    private let leftStackView = UIStackView()
    private let rightStackView = UIStackView()

    var viewModel: ConversationViewModel? {
        didSet {
            for stackView in [leftStackView, rightStackView] {
                for view in stackView.arrangedSubviews {
                    stackView.removeArrangedSubview(view)
                    view.removeFromSuperview()
                }
            }

            let accountViewModels = viewModel?.accountViewModels ?? []
            let accountCount = accountViewModels.count

            rightStackView.isHidden = accountCount == 1

            for (index, accountViewModel) in accountViewModels.enumerated() {
                let imageView = AnimatedImageView()

                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.kf.setImage(with: accountViewModel.avatarURL())

                if accountCount == 2 && index == 1
                    || accountCount == 3 && index != 0
                    || accountCount > 3 && index % 2 != 0 {
                    rightStackView.addArrangedSubview(imageView)
                } else {
                    leftStackView.addArrangedSubview(imageView)
                }
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        initialSetup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = bounds.height / 2
    }
}

private extension ConversationAvatarsView {
    func initialSetup() {
        backgroundColor = .clear
        clipsToBounds = true

        let containerStackView = UIStackView()

        addSubview(containerStackView)
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.distribution = .fillEqually
        containerStackView.spacing = .ultraCompactSpacing
        leftStackView.distribution = .fillEqually
        leftStackView.spacing = .ultraCompactSpacing
        leftStackView.axis = .vertical
        rightStackView.distribution = .fillEqually
        rightStackView.spacing = .ultraCompactSpacing
        rightStackView.axis = .vertical
        containerStackView.addArrangedSubview(leftStackView)
        containerStackView.addArrangedSubview(rightStackView)

        NSLayoutConstraint.activate([
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
