// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import UIKit
import ViewModels

final class ConversationView: UIView {
    let avatarsView = ConversationAvatarsView()
    let displayNamesLabel = UILabel()
    let timeLabel = UILabel()
    let statusBodyView = StatusBodyView()

    private var conversationConfiguration: ConversationContentConfiguration

    init(configuration: ConversationContentConfiguration) {
        conversationConfiguration = configuration

        super.init(frame: .zero)

        initialSetup()
        applyConversationConfiguration()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ConversationView {
    static func estimatedHeight(width: CGFloat,
                                identityContext: IdentityContext,
                                conversation: Conversation) -> CGFloat {
        guard let status = conversation.lastStatus else { return UITableView.automaticDimension }

        let bodyWidth = width - .defaultSpacing - .avatarDimension

        return .defaultSpacing * 2
            + UIFont.preferredFont(forTextStyle: .headline).lineHeight
            + StatusBodyView.estimatedHeight(
                width: bodyWidth,
                identityContext: identityContext,
                status: status,
                configuration: .default)
    }
}

extension ConversationView: UIContentView {
    var configuration: UIContentConfiguration {
        get { conversationConfiguration }
        set {
            guard let conversationConfiguration = newValue as? ConversationContentConfiguration else { return }

            self.conversationConfiguration = conversationConfiguration

            applyConversationConfiguration()
        }
    }
}

private extension ConversationView {
    func initialSetup() {
        let containerStackView = UIStackView()
        let sideStackView = UIStackView()
        let mainStackView = UIStackView()
        let namesTimeStackView = UIStackView()

        addSubview(containerStackView)
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.spacing = .defaultSpacing

        sideStackView.alignment = .top
        sideStackView.spacing = .compactSpacing
        sideStackView.addArrangedSubview(avatarsView)
        containerStackView.addArrangedSubview(sideStackView)

        namesTimeStackView.spacing = .compactSpacing
        namesTimeStackView.alignment = .top
        namesTimeStackView.addArrangedSubview(displayNamesLabel)
        namesTimeStackView.addArrangedSubview(timeLabel)

        mainStackView.axis = .vertical
        mainStackView.spacing = .compactSpacing
        mainStackView.addArrangedSubview(namesTimeStackView)
        mainStackView.addArrangedSubview(statusBodyView)
        containerStackView.addArrangedSubview(mainStackView)

        displayNamesLabel.font = .preferredFont(forTextStyle: .headline)
        displayNamesLabel.adjustsFontForContentSizeCategory = true
        displayNamesLabel.numberOfLines = 0

        timeLabel.font = .preferredFont(forTextStyle: .subheadline)
        timeLabel.adjustsFontForContentSizeCategory = true
        timeLabel.textColor = .secondaryLabel
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)

        statusBodyView.alpha = 0.5
        statusBodyView.isUserInteractionEnabled = false

        let avatarsHeightConstraint = avatarsView.heightAnchor.constraint(equalToConstant: .avatarDimension)

        avatarsHeightConstraint.priority = .justBelowMax

        NSLayoutConstraint.activate([
            containerStackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            containerStackView.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor),
            avatarsView.widthAnchor.constraint(equalToConstant: .avatarDimension),
            avatarsHeightConstraint,
            sideStackView.widthAnchor.constraint(equalToConstant: .avatarDimension)
        ])
    }

    func applyConversationConfiguration() {
        let viewModel = conversationConfiguration.viewModel
        let displayNames = ListFormatter.localizedString(byJoining: viewModel.accountViewModels.map(\.displayName))
        let mutableDisplayNames = NSMutableAttributedString(string: displayNames)

        mutableDisplayNames.insert(
            emojis: viewModel.accountViewModels.map(\.emojis).reduce([], +),
            view: displayNamesLabel)
        mutableDisplayNames.resizeAttachments(toLineHeight: displayNamesLabel.font.lineHeight)

        displayNamesLabel.attributedText = mutableDisplayNames
        timeLabel.text = viewModel.statusViewModel?.time
        statusBodyView.viewModel = viewModel.statusViewModel
        avatarsView.viewModel = viewModel
    }
}
