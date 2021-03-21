// Copyright © 2020 Metabolist. All rights reserved.

// swiftlint:disable file_length
import Combine
import Mastodon
import SDWebImage
import UIKit
import ViewModels

final class StatusView: UIView {
    let avatarImageView = SDAnimatedImageView()
    let rebloggerAvatarImageView = SDAnimatedImageView()
    let avatarButton = UIButton()
    let infoIcon = UIImageView()
    let infoLabel = AnimatedAttachmentLabel()
    let rebloggerButton = UIButton()
    let displayNameLabel = AnimatedAttachmentLabel()
    let accountLabel = UILabel()
    let nameButton = UIButton()
    let timeLabel = UILabel()
    let bodyView = StatusBodyView()
    let contextParentTimeLabel = UILabel()
    let visibilityImageView = UIImageView()
    let applicationButton = UIButton(type: .system)
    let rebloggedByButton = UIButton()
    let favoritedByButton = UIButton()
    let replyButton = UIButton()
    let reblogButton = UIButton()
    let favoriteButton = UIButton()
    let shareButton = UIButton()
    let menuButton = UIButton()
    let buttonsStackView = UIStackView()
    let reportSelectionSwitch = UISwitch()

    private let containerStackView = UIStackView()
    private let sideStackView = UIStackView()
    private let mainStackView = UIStackView()
    private let avatarContainerView = UIView()
    private let nameAccountContainerStackView = UIStackView()
    private let nameAccountTimeStackView = UIStackView()
    private let contextParentTimeApplicationStackView = UIStackView()
    private let timeVisibilityDividerLabel = UILabel()
    private let visibilityApplicationDividerLabel = UILabel()
    private let contextParentTopNameAccountSpacingView = UIView()
    private let contextParentBottomNameAccountSpacingView = UIView()
    private let interactionsDividerView = UIView()
    private let interactionsStackView = UIStackView()
    private let buttonsDividerView = UIView()
    private let inReplyToView = UIView()
    private let hasReplyFollowingView = UIView()
    private var statusConfiguration: StatusContentConfiguration
    private let avatarWidthConstraint: NSLayoutConstraint
    private let avatarHeightConstraint: NSLayoutConstraint
    private var cancellables = Set<AnyCancellable>()

    init(configuration: StatusContentConfiguration) {
        self.statusConfiguration = configuration

        avatarWidthConstraint = avatarImageView.widthAnchor.constraint(equalToConstant: .avatarDimension)
        avatarHeightConstraint = avatarImageView.heightAnchor.constraint(equalToConstant: .avatarDimension)
        avatarHeightConstraint.priority = .justBelowMax

        super.init(frame: .zero)

        initialSetup()
        applyStatusConfiguration()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func accessibilityActivate() -> Bool {
        if reportSelectionSwitch.isHidden, !statusConfiguration.viewModel.shouldShowContent {
            statusConfiguration.viewModel.toggleShowContent()
            accessibilityAttributedLabel = accessibilityAttributedLabel(forceShowContent: true)

            return true
        } else {
            return super.accessibilityActivate()
        }
    }
}

extension StatusView {
    static func estimatedHeight(width: CGFloat,
                                identityContext: IdentityContext,
                                status: Status,
                                configuration: CollectionItem.StatusConfiguration) -> CGFloat {
        var height = CGFloat.defaultSpacing * 2
        let bodyWidth = width - .defaultSpacing - .avatarDimension

        if status.reblog != nil || configuration.isPinned {
            height += UIFont.preferredFont(forTextStyle: .caption1).lineHeight + .compactSpacing
        }

        if configuration.isContextParent {
            height += .avatarDimension + .minimumButtonDimension * 2.5 + .hairline * 2 + .compactSpacing * 4
        } else {
            height += UIFont.preferredFont(forTextStyle: .headline).lineHeight
                + .compactSpacing + .minimumButtonDimension / 2
        }

        height += StatusBodyView.estimatedHeight(
            width: bodyWidth,
            identityContext: identityContext,
            status: status,
            configuration: configuration)
            + .compactSpacing

        return height
    }

    func refreshAccessibilityLabel() {
        accessibilityAttributedLabel = accessibilityAttributedLabel(forceShowContent: false)
    }
}

extension StatusView: UIContentView {
    var configuration: UIContentConfiguration {
        get { statusConfiguration }
        set {
            guard let statusConfiguration = newValue as? StatusContentConfiguration else { return }

            self.statusConfiguration = statusConfiguration

            applyStatusConfiguration()
        }
    }
}

extension StatusView: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction) -> Bool {
        switch interaction {
        case .invokeDefaultAction:
            statusConfiguration.viewModel.urlSelected(URL)
            return false
        case .preview: return false
        case .presentActions: return false
        @unknown default: return false
        }
    }
}

private extension StatusView {
    static let actionButtonTitleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 0)
    static let reblogAvatarDimension: CGFloat = .avatarDimension * 7 / 8

    var actionButtons: [UIButton] {
        [replyButton, reblogButton, favoriteButton, shareButton, menuButton]
    }

    // swiftlint:disable function_body_length
    func initialSetup() {
        addSubview(containerStackView)
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.spacing = .defaultSpacing

        infoIcon.tintColor = .secondaryLabel
        infoIcon.contentMode = .scaleAspectFit
        infoIcon.setContentCompressionResistancePriority(.required, for: .vertical)

        sideStackView.axis = .vertical
        sideStackView.alignment = .trailing
        sideStackView.spacing = .compactSpacing
        sideStackView.addArrangedSubview(infoIcon)
        sideStackView.addArrangedSubview(UIView())
        containerStackView.addArrangedSubview(sideStackView)

        mainStackView.axis = .vertical
        mainStackView.spacing = .compactSpacing
        containerStackView.addArrangedSubview(mainStackView)

        infoLabel.font = .preferredFont(forTextStyle: .caption1)
        infoLabel.textColor = .secondaryLabel
        infoLabel.adjustsFontForContentSizeCategory = true
        infoLabel.isUserInteractionEnabled = true
        infoLabel.setContentHuggingPriority(.required, for: .vertical)
        mainStackView.addArrangedSubview(infoLabel)

        infoLabel.addSubview(rebloggerButton)
        rebloggerButton.translatesAutoresizingMaskIntoConstraints = false
        rebloggerButton.addAction(
            UIAction { [weak self] _ in self?.statusConfiguration.viewModel.rebloggerAccountSelected() },
            for: .touchUpInside)

        let rebloggerTouchStartAction = UIAction { [weak self] _ in self?.infoLabel.alpha = 0.75 }

        rebloggerButton.addAction(rebloggerTouchStartAction, for: .touchDown)
        rebloggerButton.addAction(rebloggerTouchStartAction, for: .touchDragEnter)

        let rebloggerTouchEnd = UIAction { [weak self] _ in self?.infoLabel.alpha = 1 }

        rebloggerButton.addAction(rebloggerTouchEnd, for: .touchDragExit)
        rebloggerButton.addAction(rebloggerTouchEnd, for: .touchUpInside)
        rebloggerButton.addAction(rebloggerTouchEnd, for: .touchUpOutside)
        rebloggerButton.addAction(rebloggerTouchEnd, for: .touchCancel)

        displayNameLabel.font = .preferredFont(forTextStyle: .headline)
        displayNameLabel.adjustsFontForContentSizeCategory = true
        displayNameLabel.setContentHuggingPriority(.required, for: .horizontal)
        displayNameLabel.setContentHuggingPriority(.required, for: .vertical)
        displayNameLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameAccountTimeStackView.addArrangedSubview(displayNameLabel)

        accountLabel.font = .preferredFont(forTextStyle: .subheadline)
        accountLabel.adjustsFontForContentSizeCategory = true
        accountLabel.textColor = .secondaryLabel
        accountLabel.setContentHuggingPriority(.required, for: .horizontal)
        accountLabel.setContentHuggingPriority(.required, for: .vertical)
        nameAccountTimeStackView.addArrangedSubview(accountLabel)

        timeLabel.font = .preferredFont(forTextStyle: .subheadline)
        timeLabel.adjustsFontForContentSizeCategory = true
        timeLabel.textColor = .secondaryLabel
        timeLabel.textAlignment = .right
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        timeLabel.setContentHuggingPriority(.required, for: .vertical)
        nameAccountTimeStackView.addArrangedSubview(timeLabel)

        nameAccountContainerStackView.spacing = .defaultSpacing
        nameAccountContainerStackView.addArrangedSubview(nameAccountTimeStackView)
        mainStackView.addArrangedSubview(nameAccountContainerStackView)

        nameButton.translatesAutoresizingMaskIntoConstraints = false
        nameButton.addAction(
            UIAction { [weak self] _ in
                self?.displayNameLabel.alpha = 1
                self?.accountLabel.alpha = 1
                self?.statusConfiguration.viewModel.accountSelected()
            },
            for: .touchUpInside)
        nameButton.addAction(
            UIAction { [weak self] _ in
                self?.displayNameLabel.alpha = 0.5
                self?.accountLabel.alpha = 0.5
            },
            for: .touchDown)

        let unhighlightAction = UIAction { [weak self] _ in
            self?.displayNameLabel.alpha = 1
            self?.accountLabel.alpha = 1
        }

        nameButton.addAction(unhighlightAction, for: .touchUpOutside)
        nameButton.addAction(unhighlightAction, for: .touchCancel)
        nameButton.addAction(unhighlightAction, for: .touchDragOutside)
        nameAccountContainerStackView.addSubview(nameButton)

        mainStackView.addArrangedSubview(bodyView)

        contextParentTimeLabel.font = .preferredFont(forTextStyle: .footnote)
        contextParentTimeLabel.adjustsFontForContentSizeCategory = true
        contextParentTimeLabel.textColor = .secondaryLabel
        contextParentTimeLabel.setContentHuggingPriority(.required, for: .horizontal)
        contextParentTimeApplicationStackView.addArrangedSubview(contextParentTimeLabel)

        for label in [timeVisibilityDividerLabel, visibilityApplicationDividerLabel] {
            label.font = .preferredFont(forTextStyle: .footnote)
            label.adjustsFontForContentSizeCategory = true
            label.textColor = .secondaryLabel
            label.text = "•"
            label.setContentHuggingPriority(.required, for: .horizontal)
            label.isAccessibilityElement = false
        }

        contextParentTimeApplicationStackView.addArrangedSubview(timeVisibilityDividerLabel)

        contextParentTimeApplicationStackView.addArrangedSubview(visibilityImageView)
        visibilityImageView.contentMode = .scaleAspectFit
        visibilityImageView.tintColor = .secondaryLabel
        visibilityImageView.isAccessibilityElement = true

        contextParentTimeApplicationStackView.addArrangedSubview(visibilityApplicationDividerLabel)

        applicationButton.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        applicationButton.titleLabel?.adjustsFontForContentSizeCategory = true
        applicationButton.setTitleColor(.secondaryLabel, for: .disabled)
        applicationButton.setContentHuggingPriority(.required, for: .horizontal)
        applicationButton.addAction(
            UIAction { [weak self] _ in
                guard
                    let viewModel = self?.statusConfiguration.viewModel,
                    let url = viewModel.applicationURL
                else { return }

                viewModel.urlSelected(url)
            },
            for: .touchUpInside)
        contextParentTimeApplicationStackView.addArrangedSubview(applicationButton)
        contextParentTimeApplicationStackView.addArrangedSubview(UIView())

        contextParentTimeApplicationStackView.spacing = .compactSpacing
        mainStackView.addArrangedSubview(contextParentTimeApplicationStackView)

        for view in [interactionsDividerView, buttonsDividerView] {
            view.backgroundColor = .opaqueSeparator
            view.heightAnchor.constraint(equalToConstant: .hairline).isActive = true
        }

        mainStackView.addArrangedSubview(interactionsDividerView)
        mainStackView.addArrangedSubview(interactionsStackView)
        mainStackView.addArrangedSubview(buttonsDividerView)

        rebloggedByButton.contentHorizontalAlignment = .leading
        rebloggedByButton.addAction(
            UIAction { [weak self] _ in self?.statusConfiguration.viewModel.rebloggedBySelected() },
            for: .touchUpInside)
        interactionsStackView.addArrangedSubview(rebloggedByButton)

        favoritedByButton.contentHorizontalAlignment = .leading
        favoritedByButton.addAction(
            UIAction { [weak self] _ in self?.statusConfiguration.viewModel.favoritedBySelected() },
            for: .touchUpInside)
        interactionsStackView.addArrangedSubview(favoritedByButton)
        interactionsStackView.distribution = .fillEqually

        replyButton.addAction(
            UIAction { [weak self] _ in self?.statusConfiguration.viewModel.reply() },
            for: .touchUpInside)
        replyButton.accessibilityLabel = NSLocalizedString("status.reply-button.accessibility-label", comment: "")

        reblogButton.addAction(
            UIAction { [weak self] _ in
                guard let self = self,
                      !self.statusConfiguration.viewModel.identityContext.appPreferences.requireDoubleTapToReblog
                else { return }

                self.reblog()
            },
            for: .touchUpInside)
        reblogButton.addTarget(self, action: #selector(reblogButtonDoubleTap(sender:event:)), for: .touchDownRepeat)

        favoriteButton.addAction(
            UIAction { [weak self] _ in
                guard let self = self,
                      !self.statusConfiguration.viewModel.identityContext.appPreferences.requireDoubleTapToFavorite
                else { return }

                self.favorite()
            },
            for: .touchUpInside)
        favoriteButton.accessibilityLabel = NSLocalizedString("status.favorite-button.accessibility-label", comment: "")
        favoriteButton.addTarget(self, action: #selector(favoriteButtonDoubleTap(sender:event:)), for: .touchDownRepeat)

        shareButton.addAction(
            UIAction { [weak self] _ in self?.statusConfiguration.viewModel.shareStatus() },
            for: .touchUpInside)

        menuButton.showsMenuAsPrimaryAction = true

        for button in actionButtons {
            button.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.tintColor = .secondaryLabel
            button.setTitleColor(.secondaryLabel, for: .normal)
            button.titleEdgeInsets = Self.actionButtonTitleEdgeInsets
            buttonsStackView.addArrangedSubview(button)
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: .minimumButtonDimension).isActive = true
        }

        buttonsStackView.distribution = .equalSpacing
        mainStackView.addArrangedSubview(buttonsStackView)

        avatarContainerView.addSubview(avatarImageView)
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.layer.cornerRadius = .avatarDimension / 2
        avatarImageView.clipsToBounds = true

        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.addSubview(avatarButton)
        avatarImageView.isUserInteractionEnabled = true
        avatarButton.setBackgroundImage(.highlightedButtonBackground, for: .highlighted)

        avatarButton.addAction(
            UIAction { [weak self] _ in self?.statusConfiguration.viewModel.accountSelected() },
            for: .touchUpInside)

        avatarContainerView.addSubview(rebloggerAvatarImageView)
        rebloggerAvatarImageView.translatesAutoresizingMaskIntoConstraints = false
        rebloggerAvatarImageView.layer.cornerRadius = .avatarDimension / 4
        rebloggerAvatarImageView.clipsToBounds = true
        rebloggerAvatarImageView.isHidden = true

        for view in [inReplyToView, hasReplyFollowingView] {
            addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = .opaqueSeparator
            view.widthAnchor.constraint(equalToConstant: .hairline).isActive = true
        }

        containerStackView.addArrangedSubview(reportSelectionSwitch)
        reportSelectionSwitch.setContentCompressionResistancePriority(.required, for: .horizontal)
        reportSelectionSwitch.setContentHuggingPriority(.required, for: .horizontal)
        reportSelectionSwitch.setContentHuggingPriority(.defaultLow, for: .vertical)
        reportSelectionSwitch.isHidden = true

        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor),
            avatarContainerView.widthAnchor.constraint(equalToConstant: .avatarDimension),
            avatarContainerView.heightAnchor.constraint(equalToConstant: .avatarDimension),
            avatarWidthConstraint,
            avatarHeightConstraint,
            avatarImageView.topAnchor.constraint(equalTo: avatarContainerView.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarContainerView.leadingAnchor),
            rebloggerAvatarImageView.widthAnchor.constraint(equalToConstant: .avatarDimension / 2),
            rebloggerAvatarImageView.heightAnchor.constraint(equalToConstant: .avatarDimension / 2),
            rebloggerAvatarImageView.trailingAnchor.constraint(equalTo: avatarContainerView.trailingAnchor),
            rebloggerAvatarImageView.bottomAnchor.constraint(equalTo: avatarContainerView.bottomAnchor),
            sideStackView.widthAnchor.constraint(equalToConstant: .avatarDimension),
            avatarButton.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            avatarButton.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            avatarButton.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
            avatarButton.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor),
            infoIcon.centerYAnchor.constraint(equalTo: infoLabel.centerYAnchor),
            nameButton.leadingAnchor.constraint(equalTo: displayNameLabel.leadingAnchor),
            nameButton.topAnchor.constraint(equalTo: displayNameLabel.topAnchor),
            nameButton.trailingAnchor.constraint(equalTo: accountLabel.trailingAnchor),
            nameButton.bottomAnchor.constraint(equalTo: accountLabel.bottomAnchor),
            contextParentTimeApplicationStackView.heightAnchor.constraint(
                greaterThanOrEqualToConstant: .minimumButtonDimension / 2),
            interactionsStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: .minimumButtonDimension),
            rebloggerButton.leadingAnchor.constraint(equalTo: infoLabel.leadingAnchor),
            rebloggerButton.topAnchor.constraint(equalTo: infoLabel.topAnchor),
            rebloggerButton.trailingAnchor.constraint(equalTo: infoLabel.trailingAnchor),
            rebloggerButton.bottomAnchor.constraint(equalTo: infoLabel.bottomAnchor)
        ])

        NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)
            .sink { [weak self] _ in self?.configureUserInteractionEnabledForAccessibility() }
            .store(in: &cancellables)
    }

    func applyStatusConfiguration() {
        let viewModel = statusConfiguration.viewModel
        let isContextParent = viewModel.configuration.isContextParent
        let mutableDisplayName = NSMutableAttributedString(string: viewModel.accountViewModel.displayName)
        let isAuthenticated = viewModel.identityContext.identity.authenticated
            && !viewModel.identityContext.identity.pending

        menuButton.menu = menu(viewModel: viewModel)

        avatarImageView.sd_setImage(with: viewModel.avatarURL)
        avatarButton.accessibilityLabel = String.localizedStringWithFormat(
            NSLocalizedString("account.avatar.accessibility-label-%@", comment: ""),
            viewModel.accountViewModel.displayName)

        sideStackView.isHidden = isContextParent

        let avatarDimension = viewModel.isReblog ? Self.reblogAvatarDimension : .avatarDimension

        avatarWidthConstraint.constant = avatarDimension
        avatarHeightConstraint.constant = avatarDimension
        avatarImageView.layer.cornerRadius = avatarDimension / 2
        rebloggerAvatarImageView.isHidden = !viewModel.isReblog
        rebloggerAvatarImageView.sd_setImage(with: viewModel.isReblog ? viewModel.rebloggerAvatarURL : nil)

        if isContextParent, avatarContainerView.superview !== nameAccountContainerStackView {
            nameAccountContainerStackView.insertArrangedSubview(avatarContainerView, at: 0)
        } else if avatarContainerView.superview !== sideStackView {
            sideStackView.insertArrangedSubview(avatarContainerView, at: 1)
        }

        NSLayoutConstraint.activate([
            inReplyToView.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            inReplyToView.topAnchor.constraint(equalTo: topAnchor),
            inReplyToView.bottomAnchor.constraint(equalTo: avatarImageView.topAnchor),
            hasReplyFollowingView.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            hasReplyFollowingView.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
            hasReplyFollowingView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        inReplyToView.isHidden = !viewModel.configuration.isReplyInContext
        hasReplyFollowingView.isHidden = !viewModel.configuration.hasReplyFollowing

        if viewModel.isReblog {
            let attributedTitle = "status.reblogged-by".localizedBolding(
                displayName: viewModel.rebloggedByDisplayName,
                emojis: viewModel.rebloggedByDisplayNameEmojis,
                label: infoLabel,
                identityContext: viewModel.identityContext)
            let highlightedAttributedTitle = NSMutableAttributedString(attributedString: attributedTitle)

            highlightedAttributedTitle.addAttribute(
                .foregroundColor,
                value: UIColor.tertiaryLabel,
                range: .init(location: 0, length: highlightedAttributedTitle.length))

            infoLabel.attributedText = attributedTitle
            infoIcon.image = UIImage(
                systemName: "arrow.2.squarepath",
                withConfiguration: UIImage.SymbolConfiguration(scale: .small))
            infoLabel.isHidden = false
            infoIcon.isHidden = false
            rebloggerButton.isHidden = false
        } else if viewModel.configuration.isPinned {
            let pinnedText: String

            switch viewModel.identityContext.appPreferences.statusWord {
            case .toot:
                pinnedText = NSLocalizedString("status.pinned.toot", comment: "")
            case .post:
                pinnedText = NSLocalizedString("status.pinned.post", comment: "")
            }

            infoLabel.text = pinnedText
            infoIcon.centerYAnchor.constraint(equalTo: infoLabel.centerYAnchor).isActive = true
            infoIcon.image = UIImage(
                systemName: "pin",
                withConfiguration: UIImage.SymbolConfiguration(scale: .small))
            infoLabel.isHidden = false
            infoIcon.isHidden = false
            rebloggerButton.isHidden = true
        } else {
            infoLabel.text = nil
            infoIcon.image = nil
            infoLabel.isHidden = true
            infoIcon.isHidden = true
            rebloggerButton.setTitle(nil, for: .normal)
            rebloggerButton.setImage(nil, for: .normal)
            rebloggerButton.isHidden = true
        }

        mutableDisplayName.insert(emojis: viewModel.accountViewModel.emojis,
                                  view: displayNameLabel,
                                  identityContext: viewModel.identityContext)
        mutableDisplayName.resizeAttachments(toLineHeight: displayNameLabel.font.lineHeight)
        displayNameLabel.attributedText = mutableDisplayName
        accountLabel.text = viewModel.accountName

        let nameButtonAccessibilityAttributedLabel = NSMutableAttributedString(attributedString: mutableDisplayName)

        nameButtonAccessibilityAttributedLabel.appendWithSeparator(viewModel.accountName)
        nameButton.accessibilityAttributedLabel = nameButtonAccessibilityAttributedLabel

        nameAccountTimeStackView.axis = isContextParent ? .vertical : .horizontal
        nameAccountTimeStackView.alignment = isContextParent ? .leading : .fill
        nameAccountTimeStackView.spacing = isContextParent ? 0 : .compactSpacing

        contextParentTopNameAccountSpacingView.removeFromSuperview()
        contextParentBottomNameAccountSpacingView.removeFromSuperview()

        if isContextParent {
            nameAccountTimeStackView.insertArrangedSubview(contextParentTopNameAccountSpacingView, at: 0)
            nameAccountTimeStackView.addArrangedSubview(contextParentBottomNameAccountSpacingView)
            contextParentTopNameAccountSpacingView.heightAnchor
                .constraint(equalTo: contextParentBottomNameAccountSpacingView.heightAnchor).isActive = true
        }

        timeLabel.text = viewModel.time
        timeLabel.accessibilityLabel = viewModel.accessibilityTime
        timeLabel.isHidden = isContextParent

        bodyView.viewModel = viewModel

        contextParentTimeLabel.text = viewModel.contextParentTime
        contextParentTimeLabel.accessibilityLabel = viewModel.accessibilityContextParentTime
        visibilityImageView.image = UIImage(systemName: viewModel.visibility.systemImageName)
        visibilityImageView.accessibilityLabel = viewModel.visibility.title
        visibilityApplicationDividerLabel.isHidden = viewModel.applicationName == nil
        applicationButton.isHidden = viewModel.applicationName == nil
        applicationButton.setTitle(viewModel.applicationName, for: .normal)
        applicationButton.isEnabled = viewModel.applicationURL != nil
        contextParentTimeApplicationStackView.isHidden = !isContextParent

        let noReblogs = viewModel.reblogsCount == 0
        let noFavorites = viewModel.favoritesCount == 0
        let noInteractions = !isContextParent || (noReblogs && noFavorites)

        rebloggedByButton.setAttributedLocalizedTitle(
            localizationKey: "status.reblogs-count",
            count: viewModel.reblogsCount)
        rebloggedByButton.isHidden = noReblogs
        favoritedByButton.setAttributedLocalizedTitle(
            localizationKey: "status.favorites-count",
            count: viewModel.favoritesCount)
        favoritedByButton.isHidden = noFavorites

        interactionsDividerView.isHidden = noInteractions
        interactionsStackView.isHidden = noInteractions
        buttonsDividerView.isHidden = !isContextParent

        for button in actionButtons {
            button.contentHorizontalAlignment = isContextParent ? .center : .leading

            if isContextParent {
                button.heightAnchor.constraint(equalToConstant: .minimumButtonDimension).isActive = true
            } else {
                button.heightAnchor.constraint(
                    greaterThanOrEqualToConstant: .minimumButtonDimension * 2 / 3).isActive = true
            }
        }

        setButtonImages(font: isContextParent
                            ? .preferredFont(forTextStyle: .title3)
                            : .preferredFont(forTextStyle: .subheadline))

        replyButton.setCountTitle(count: viewModel.repliesCount, isContextParent: isContextParent)
        replyButton.isEnabled = isAuthenticated
        replyButton.menu = authenticatedIdentitiesMenu { viewModel.reply(identity: $0) }

        if viewModel.identityContext.appPreferences.showReblogAndFavoriteCounts || isContextParent {
            reblogButton.setCountTitle(count: viewModel.reblogsCount, isContextParent: isContextParent)
            favoriteButton.setCountTitle(count: viewModel.favoritesCount, isContextParent: isContextParent)
        } else {
            reblogButton.setTitle(nil, for: .normal)
            favoriteButton.setTitle(nil, for: .normal)
        }

        setReblogButtonColor(reblogged: viewModel.reblogged)
        reblogButton.isEnabled = viewModel.canBeReblogged && isAuthenticated
        reblogButton.menu = authenticatedIdentitiesMenu { viewModel.toggleReblogged(identityId: $0.id) }

        setFavoriteButtonColor(favorited: viewModel.favorited)
        favoriteButton.isEnabled = isAuthenticated
        favoriteButton.menu = authenticatedIdentitiesMenu { viewModel.toggleFavorited(identityId: $0.id) }

        shareButton.tag = viewModel.sharingURL?.hashValue ?? 0

        menuButton.isEnabled = isAuthenticated

        reportSelectionSwitch.isOn = viewModel.selectedForReport

        isAccessibilityElement = !viewModel.configuration.isContextParent

        accessibilityAttributedLabel = accessibilityAttributedLabel(forceShowContent: false)

        configureUserInteractionEnabledForAccessibility()

        accessibilityCustomActions = accessibilityCustomActions(viewModel: viewModel)
    }

    func menu(viewModel: StatusViewModel) -> UIMenu {
        var sections = [UIMenu]()

        var firstSectionItems = [
            UIAction(
                title: viewModel.bookmarked
                    ? NSLocalizedString("status.unbookmark", comment: "")
                    : NSLocalizedString("status.bookmark", comment: ""),
                image: UIImage(systemName: "bookmark")) { _ in
                viewModel.toggleBookmarked()
            }
        ]

        if let pinned = viewModel.pinned {
            firstSectionItems.append(UIAction(
                title: pinned
                    ? NSLocalizedString("status.unpin", comment: "")
                    : NSLocalizedString("status.pin", comment: ""),
                image: UIImage(systemName: "pin")) { _ in
                viewModel.togglePinned()
            })
        }

        sections.append(UIMenu(options: .displayInline, children: firstSectionItems))

        var secondSectionItems = [UIAction]()

        if viewModel.isMine {
            secondSectionItems += [
                UIAction(
                    title: viewModel.muted
                        ? NSLocalizedString("status.unmute", comment: "")
                        : NSLocalizedString("status.mute", comment: ""),
                    image: UIImage(systemName: viewModel.muted ? "speaker" : "speaker.slash")) { _ in
                    viewModel.toggleMuted()
                },
                UIAction(
                    title: NSLocalizedString("status.delete", comment: ""),
                    image: UIImage(systemName: "trash"),
                    attributes: .destructive) { _ in
                    viewModel.confirmDelete(redraft: false)
                },
                UIAction(
                    title: NSLocalizedString("status.delete-and-redraft", comment: ""),
                    image: UIImage(systemName: "trash.circle"),
                    attributes: .destructive) { _ in
                    viewModel.confirmDelete(redraft: true)
                }
            ]

            sections.append(UIMenu(options: .displayInline, children: secondSectionItems))
        } else {
            if let relationship = viewModel.accountViewModel.relationship {
                if relationship.muting {
                    secondSectionItems.append(UIAction(
                        title: NSLocalizedString("account.unmute", comment: ""),
                        image: UIImage(systemName: "speaker")) { _ in
                        viewModel.accountViewModel.confirmUnmute()
                    })
                } else {
                    secondSectionItems.append(UIAction(
                        title: NSLocalizedString("account.mute", comment: ""),
                        image: UIImage(systemName: "speaker.slash")) { _ in
                        viewModel.accountViewModel.confirmMute()
                    })
                }

                if relationship.blocking {
                    secondSectionItems.append(UIAction(
                        title: NSLocalizedString("account.unblock", comment: ""),
                        image: UIImage(systemName: "slash.circle"),
                        attributes: .destructive) { _ in
                        viewModel.accountViewModel.confirmUnblock()
                        })
                } else {
                    secondSectionItems.append(UIAction(
                        title: NSLocalizedString("account.block", comment: ""),
                        image: UIImage(systemName: "slash.circle"),
                        attributes: .destructive) { _ in
                        viewModel.accountViewModel.confirmBlock()
                    })
                }
            }

            secondSectionItems.append(UIAction(
                title: NSLocalizedString("report", comment: ""),
                image: UIImage(systemName: "flag"),
                attributes: .destructive) { _ in
                viewModel.reportStatus()
            })

            sections.append(UIMenu(options: .displayInline, children: secondSectionItems))

            if !viewModel.accountViewModel.isLocal,
               let domain = viewModel.accountViewModel.domain,
               let relationship = viewModel.accountViewModel.relationship {
                let domainBlockAction: UIAction

                if relationship.domainBlocking {
                    domainBlockAction = UIAction(
                        title: String.localizedStringWithFormat(
                            NSLocalizedString("account.domain-unblock-%@", comment: ""),
                            domain),
                        image: UIImage(systemName: "slash.circle"),
                        attributes: .destructive) { _ in
                        viewModel.accountViewModel.confirmDomainUnblock(domain: domain)
                    }
                } else {
                    domainBlockAction = UIAction(
                        title: String.localizedStringWithFormat(
                            NSLocalizedString("account.domain-block-%@", comment: ""),
                            domain),
                        image: UIImage(systemName: "slash.circle"),
                        attributes: .destructive) { _ in
                        viewModel.accountViewModel.confirmDomainBlock(domain: domain)
                    }
                }

                sections.append(UIMenu(options: .displayInline, children: [domainBlockAction]))
            }
        }

        return UIMenu(children: sections)
    }
    // swiftlint:enable function_body_length

    func accessibilityAttributedLabel(forceShowContent: Bool) -> NSAttributedString {
        let accessibilityAttributedLabel = NSMutableAttributedString(string: "")

        if !reportSelectionSwitch.isHidden, reportSelectionSwitch.isOn {
            accessibilityAttributedLabel.appendWithSeparator(NSLocalizedString("selected", comment: ""))
        }

        if !infoLabel.isHidden, let infoText = infoLabel.attributedText {
            accessibilityAttributedLabel.appendWithSeparator(infoText)
        }

        if let displayName = displayNameLabel.attributedText {
            if accessibilityAttributedLabel.string.isEmpty {
                accessibilityAttributedLabel.append(displayName)
            } else {
                accessibilityAttributedLabel.appendWithSeparator(displayName)
            }
        }

        accessibilityAttributedLabel.appendWithSeparator(
            bodyView.accessibilityAttributedLabel(forceShowContent: forceShowContent))

        if let accessibilityTime = statusConfiguration.viewModel.accessibilityTime {
            accessibilityAttributedLabel.appendWithSeparator(accessibilityTime)
        }

        if statusConfiguration.viewModel.repliesCount > 0 {
            accessibilityAttributedLabel.appendWithSeparator(
                String.localizedStringWithFormat(
                    NSLocalizedString("status.replies-count", comment: ""),
                    statusConfiguration.viewModel.repliesCount))
        }

        if statusConfiguration.viewModel.identityContext.appPreferences.showReblogAndFavoriteCounts {
            if statusConfiguration.viewModel.reblogsCount > 0 {
                accessibilityAttributedLabel.appendWithSeparator(
                    String.localizedStringWithFormat(
                        NSLocalizedString("status.reblogs-count", comment: ""),
                        statusConfiguration.viewModel.reblogsCount))
            }

            if statusConfiguration.viewModel.favoritesCount > 0 {
                accessibilityAttributedLabel.appendWithSeparator(
                    String.localizedStringWithFormat(
                        NSLocalizedString("status.favorites-count", comment: ""),
                        statusConfiguration.viewModel.favoritesCount))
            }
        }

        return accessibilityAttributedLabel
    }

    func setButtonImages(font: UIFont) {
        let visibility = statusConfiguration.viewModel.visibility
        let reblogSystemImageName: String

        if statusConfiguration.viewModel.configuration.isContextParent {
            reblogSystemImageName = "arrow.2.squarepath"
        } else {
            switch visibility {
            case .public, .unlisted:
                reblogSystemImageName = "arrow.2.squarepath"
            default:
                reblogSystemImageName = visibility.systemImageName
            }
        }

        replyButton.setImage(UIImage(systemName: "bubble.right",
                                     withConfiguration: UIImage.SymbolConfiguration(pointSize: font.pointSize)),
                             for: .normal)
        reblogButton.setImage(UIImage(systemName: reblogSystemImageName,
                                      withConfiguration: UIImage.SymbolConfiguration(
                                        pointSize: font.pointSize,
                                        weight: statusConfiguration.viewModel.reblogged ? .bold : .regular)),
                             for: .normal)
        favoriteButton.setImage(UIImage(systemName: statusConfiguration.viewModel.favorited ? "star.fill" : "star",
                                        withConfiguration: UIImage.SymbolConfiguration(pointSize: font.pointSize)),
                                for: .normal)
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up",
                                     withConfiguration: UIImage.SymbolConfiguration(pointSize: font.pointSize)),
                             for: .normal)
        menuButton.setImage(UIImage(systemName: "ellipsis",
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: font.pointSize)),
                            for: .normal)
    }

    @objc func reblogButtonDoubleTap(sender: UIButton, event: UIEvent) {
        guard
            statusConfiguration.viewModel.identityContext.appPreferences.requireDoubleTapToReblog,
            event.allTouches?.first?.tapCount == 2 else {
            return
        }

        reblog()
    }

    @objc func favoriteButtonDoubleTap(sender: UIButton, event: UIEvent) {
        guard
            statusConfiguration.viewModel.identityContext.appPreferences.requireDoubleTapToFavorite,
            event.allTouches?.first?.tapCount == 2 else {
            return
        }

        favorite()
    }

    func setReblogButtonColor(reblogged: Bool) {
        let reblogColor: UIColor = reblogged ? .systemGreen : .secondaryLabel

        reblogButton.tintColor = reblogColor
        reblogButton.setTitleColor(reblogColor, for: .normal)

        if reblogged {
            reblogButton.accessibilityLabel =
                NSLocalizedString("status.reblog-button.undo.accessibility-label", comment: "")
        } else {
            reblogButton.accessibilityLabel =
                NSLocalizedString("status.reblog-button.accessibility-label", comment: "")
        }
    }

    func setFavoriteButtonColor(favorited: Bool) {
        let favoriteColor: UIColor = favorited ? .systemYellow : .secondaryLabel

        favoriteButton.tintColor = favoriteColor
        favoriteButton.setTitleColor(favoriteColor, for: .normal)

        if favorited {
            favoriteButton.accessibilityLabel =
                NSLocalizedString("status.favorite-button.undo.accessibility-label", comment: "")
        } else {
            favoriteButton.accessibilityLabel =
                NSLocalizedString("status.favorite-button.accessibility-label", comment: "")
        }
    }

    func reblog() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if !UIAccessibility.isReduceMotionEnabled {
            UIViewPropertyAnimator.runningPropertyAnimator(
                withDuration: .defaultAnimationDuration,
                delay: 0,
                options: .curveLinear) {
                self.setReblogButtonColor(reblogged: !self.statusConfiguration.viewModel.reblogged)
                self.reblogButton.imageView?.transform =
                    self.reblogButton.imageView?.transform.rotated(by: .pi) ?? .identity
            } completion: { _ in
                self.reblogButton.imageView?.transform = .identity
            }
        }

        statusConfiguration.viewModel.toggleReblogged()
    }

    func favorite() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if !UIAccessibility.isReduceMotionEnabled {
            UIViewPropertyAnimator.runningPropertyAnimator(
                withDuration: .defaultAnimationDuration,
                delay: 0,
                options: .curveLinear) {
                self.setFavoriteButtonColor(favorited: !self.statusConfiguration.viewModel.favorited)
                self.favoriteButton.imageView?.transform =
                    self.favoriteButton.imageView?.transform.rotated(by: .pi) ?? .identity
            } completion: { _ in
                self.favoriteButton.imageView?.transform = .identity
            }
        }

        statusConfiguration.viewModel.toggleFavorited()
    }

    func configureUserInteractionEnabledForAccessibility() {
        isUserInteractionEnabled = !UIAccessibility.isVoiceOverRunning
            || statusConfiguration.viewModel.configuration.isContextParent
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func accessibilityCustomActions(viewModel: StatusViewModel) -> [UIAccessibilityCustomAction] {
        guard !viewModel.configuration.isContextParent, reportSelectionSwitch.isHidden else {
            return []
        }

        var actions = bodyView.accessibilityCustomActions ?? []

        if replyButton.isEnabled {
            actions.append(UIAccessibilityCustomAction(
                name: replyButton.accessibilityLabel ?? "") { _ in
                    viewModel.reply()

                    return true
                })
        }

        if viewModel.canBeReblogged, reblogButton.isEnabled {
            actions.append(UIAccessibilityCustomAction(
                name: reblogButton.accessibilityLabel ?? "") { [weak self] _ in
                    self?.reblog()

                    return true
                })
        }

        if favoriteButton.isEnabled {
            actions.append(UIAccessibilityCustomAction(
                name: favoriteButton.accessibilityLabel ?? "") { [weak self] _ in
                self?.favorite()

                return true
            })
        }

        if shareButton.isEnabled {
            actions.append(UIAccessibilityCustomAction(
                name: shareButton.accessibilityLabel ?? "") { _ in
                viewModel.shareStatus()

                return true
            })
        }

        actions.append(
            UIAccessibilityCustomAction(
                name: NSLocalizedString("status.accessibility.view-author-profile",
                                        comment: "")) { [weak self] _ in
                self?.statusConfiguration.viewModel.accountSelected()

                return true
            })

        if viewModel.isReblog {
            actions.append(
                UIAccessibilityCustomAction(
                    name: NSLocalizedString("status.accessibility.view-reblogger-profile",
                                            comment: "")) { [weak self] _ in
                    self?.statusConfiguration.viewModel.rebloggerAccountSelected()

                    return true
                })
        }

        actions.append(
            UIAccessibilityCustomAction(
                name: NSLocalizedString("accessibility.copy-text",
                                        comment: "")) { [weak self] _ in
                UIPasteboard.general.string = self?.bodyView.contentTextView.text

                return true
            })

        if menuButton.isEnabled {
            actions.append(UIAccessibilityCustomAction(
                name: viewModel.bookmarked
                    ? NSLocalizedString("status.unbookmark", comment: "")
                    : NSLocalizedString("status.bookmark", comment: "")) { _ in
                viewModel.toggleBookmarked()

                return true
            })

            if let pinned = viewModel.pinned {
                actions.append(UIAccessibilityCustomAction(
                    name: pinned
                        ? NSLocalizedString("status.unpin", comment: "")
                        : NSLocalizedString("status.pin", comment: "")) { _ in
                    viewModel.togglePinned()

                    return true
                })
            }

            if viewModel.isMine {
                actions += [
                    UIAccessibilityCustomAction(
                        name: viewModel.muted
                            ? NSLocalizedString("status.unmute", comment: "")
                            : NSLocalizedString("status.mute", comment: "")) { _ in
                        viewModel.toggleMuted()

                        return true
                    },
                    UIAccessibilityCustomAction(
                        name: NSLocalizedString("status.delete", comment: "")) { _ in
                        viewModel.confirmDelete(redraft: false)

                        return true
                    },
                    UIAccessibilityCustomAction(
                        name: NSLocalizedString("status.delete-and-redraft", comment: "")) { _ in
                        viewModel.confirmDelete(redraft: true)

                        return true
                    }
                ]
            } else {
                if let relationship = viewModel.accountViewModel.relationship {
                    if relationship.muting {
                        actions.append(UIAccessibilityCustomAction(
                            name: NSLocalizedString("account.unmute", comment: "")) { _ in
                            viewModel.accountViewModel.confirmUnmute()

                            return true
                        })
                    } else {
                        actions.append(UIAccessibilityCustomAction(
                            name: NSLocalizedString("account.mute", comment: "")) { _ in
                            viewModel.accountViewModel.confirmMute()

                            return true
                        })
                    }

                    if relationship.blocking {
                        actions.append(UIAccessibilityCustomAction(
                            name: NSLocalizedString("account.unblock", comment: "")) { _ in
                            viewModel.accountViewModel.confirmUnblock()

                            return true
                        })
                    } else {
                        actions.append(UIAccessibilityCustomAction(
                            name: NSLocalizedString("account.block", comment: "")) { _ in
                            viewModel.accountViewModel.confirmBlock()

                            return true
                        })
                    }
                }
                actions.append(UIAccessibilityCustomAction(
                    name: NSLocalizedString("report", comment: "")) { _ in
                    viewModel.reportStatus()

                    return true
                })

                if !viewModel.accountViewModel.isLocal,
                   let domain = viewModel.accountViewModel.domain,
                   let relationship = viewModel.accountViewModel.relationship {

                    if relationship.domainBlocking {
                        actions.append(UIAccessibilityCustomAction(
                            name: String.localizedStringWithFormat(
                                NSLocalizedString("account.domain-unblock-%@", comment: ""),
                                domain)) { _ in
                            viewModel.accountViewModel.confirmDomainUnblock(domain: domain)

                            return true
                        })
                    } else {
                        actions.append(UIAccessibilityCustomAction(
                            name: String.localizedStringWithFormat(
                                NSLocalizedString("account.domain-block-%@", comment: ""),
                                domain)) { _ in
                            viewModel.accountViewModel.confirmDomainBlock(domain: domain)

                            return true
                        })
                    }
                }
            }
        }

        return actions
    }

    func authenticatedIdentitiesMenu(action: @escaping (Identity) -> Void) -> UIMenu {
        let imageTransformer = SDImageRoundCornerTransformer(
            radius: .greatestFiniteMagnitude,
            corners: .allCorners,
            borderWidth: 0,
            borderColor: nil)

        return UIMenu(children: statusConfiguration.viewModel
                        .identityContext
                        .authenticatedOtherIdentities.map { identity in
            UIDeferredMenuElement { completion in
                let menuItemAction = UIAction(title: identity.handle) { _ in
                    action(identity)
                }

                if let image = identity.image {
                    SDWebImageManager.shared.loadImage(
                        with: image,
                        options: [.transformAnimatedImage],
                        context: [.imageTransformer: imageTransformer],
                        progress: nil) { (image, _, _, _, _, _) in
                        menuItemAction.image = image

                        completion([menuItemAction])
                    }
                } else {
                    completion([menuItemAction])
                }
            }
        })
    }
}

private extension UIButton {
    func setCountTitle(count: Int, isContextParent: Bool) {
        setTitle((isContextParent || count == 0) ? nil : String(count), for: .normal)
    }
}
// swiftlint:enable file_length
