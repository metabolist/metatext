// Copyright © 2021 Metabolist. All rights reserved.

import SDWebImage
import UIKit

final class AutocompleteItemView: UIView {
    private let imageView = SDAnimatedImageView()
    private let primaryLabel = AnimatedAttachmentLabel()
    private let secondaryLabel = UILabel()
    private let stackView = UIStackView()
    private var autocompleteItemConfiguration: AutocompleteItemContentConfiguration

    init(configuration: AutocompleteItemContentConfiguration) {
        self.autocompleteItemConfiguration = configuration

        super.init(frame: .zero)

        initialSetup()
        applyAutocompleteItemConfiguration()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AutocompleteItemView: UIContentView {
    var configuration: UIContentConfiguration {
        get { autocompleteItemConfiguration }
        set {
            guard let autocompleteItemConfiguration = newValue as? AutocompleteItemContentConfiguration else { return }

            self.autocompleteItemConfiguration = autocompleteItemConfiguration

            applyAutocompleteItemConfiguration()
        }
    }
}

private extension AutocompleteItemView {
    func initialSetup() {
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = .defaultSpacing

        stackView.addArrangedSubview(imageView)
        imageView.layer.cornerRadius = .barButtonItemDimension / 2
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill

        stackView.addArrangedSubview(primaryLabel)
        primaryLabel.adjustsFontForContentSizeCategory = true
        primaryLabel.font = .preferredFont(forTextStyle: .headline)
        primaryLabel.setContentHuggingPriority(.required, for: .horizontal)

        stackView.addArrangedSubview(secondaryLabel)
        secondaryLabel.adjustsFontForContentSizeCategory = true
        secondaryLabel.font = .preferredFont(forTextStyle: .subheadline)
        secondaryLabel.textColor = .secondaryLabel

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: .barButtonItemDimension),
            imageView.heightAnchor.constraint(equalToConstant: .barButtonItemDimension),
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
    }

    func applyAutocompleteItemConfiguration() {
        switch autocompleteItemConfiguration.item {
        case let .account(account):
            let appPreferences = autocompleteItemConfiguration.identityContext.appPreferences
            let avatarURL = (appPreferences.animateAvatars == .everywhere ? account.avatar : account.avatarStatic).url

            imageView.sd_setImage(with: avatarURL)
            imageView.isHidden = false

            let mutableDisplayName = NSMutableAttributedString(string: account.displayName)

            mutableDisplayName.insert(emojis: account.emojis,
                                      view: primaryLabel,
                                      identityContext: autocompleteItemConfiguration.identityContext)
            mutableDisplayName.resizeAttachments(toLineHeight: primaryLabel.font.lineHeight)
            primaryLabel.attributedText = mutableDisplayName
            primaryLabel.isHidden = account.displayName.isEmpty
            secondaryLabel.text = "@".appending(account.acct)
            primaryLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            secondaryLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        case let .tag(tag):
            imageView.isHidden = true
            imageView.image = nil
            primaryLabel.text = "#".appending(tag.name)
            primaryLabel.isHidden = false

            if let uses = tag.history?.compactMap({ Int($0.uses) }).reduce(0, +), uses > 0 {
                secondaryLabel.text =
                    String.localizedStringWithFormat(NSLocalizedString("tag.per-week-%ld", comment: ""), uses)
            } else {
                secondaryLabel.text = nil
            }

            primaryLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            secondaryLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        default:
            break
        }

        let accessibilityAttributedLabel = NSMutableAttributedString(string: "")

        if !primaryLabel.isHidden, let primaryLabelAttributedText = primaryLabel.attributedText {
            accessibilityAttributedLabel.append(primaryLabelAttributedText)
        }

        if let secondaryLabelText = secondaryLabel.text, !secondaryLabelText.isEmpty {
            accessibilityAttributedLabel.appendWithSeparator(secondaryLabelText)
        }

        self.accessibilityAttributedLabel = accessibilityAttributedLabel

        isAccessibilityElement = true
    }
}
