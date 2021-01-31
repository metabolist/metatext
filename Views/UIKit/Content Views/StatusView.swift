// Copyright © 2020 Metabolist. All rights reserved.

// swiftlint:disable file_length
import Kingfisher
import Mastodon
import UIKit
import ViewModels

final class StatusView: UIView {
    let avatarImageView = AnimatedImageView()
    let avatarButton = UIButton()
    let infoIcon = UIImageView()
    let infoLabel = UILabel()
    let displayNameLabel = UILabel()
    let accountLabel = UILabel()
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

    private let containerStackView = UIStackView()
    private let sideStackView = UIStackView()
    private let mainStackView = UIStackView()
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

    init(configuration: StatusContentConfiguration) {
        self.statusConfiguration = configuration

        super.init(frame: .zero)

        initialSetup()
        applyStatusConfiguration()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    var actionButtons: [UIButton] {
        [replyButton, reblogButton, favoriteButton, shareButton, menuButton]
    }

    // swiftlint:disable function_body_length
    func initialSetup() {
        addSubview(containerStackView)
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.spacing = .defaultSpacing

        infoIcon.tintColor = .secondaryLabel
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
        infoLabel.setContentHuggingPriority(.required, for: .vertical)
        mainStackView.addArrangedSubview(infoLabel)

        displayNameLabel.font = .preferredFont(forTextStyle: .headline)
        displayNameLabel.adjustsFontForContentSizeCategory = true
        displayNameLabel.setContentHuggingPriority(.required, for: .horizontal)
        displayNameLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameAccountTimeStackView.addArrangedSubview(displayNameLabel)

        accountLabel.font = .preferredFont(forTextStyle: .subheadline)
        accountLabel.adjustsFontForContentSizeCategory = true
        accountLabel.textColor = .secondaryLabel
        nameAccountTimeStackView.addArrangedSubview(accountLabel)

        timeLabel.font = .preferredFont(forTextStyle: .subheadline)
        timeLabel.adjustsFontForContentSizeCategory = true
        timeLabel.textColor = .secondaryLabel
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)
        nameAccountTimeStackView.addArrangedSubview(timeLabel)

        nameAccountContainerStackView.spacing = .defaultSpacing
        nameAccountContainerStackView.addArrangedSubview(nameAccountTimeStackView)
        mainStackView.addArrangedSubview(nameAccountContainerStackView)

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
        }

        contextParentTimeApplicationStackView.addArrangedSubview(timeVisibilityDividerLabel)

        contextParentTimeApplicationStackView.addArrangedSubview(visibilityImageView)
        visibilityImageView.contentMode = .scaleAspectFit
        visibilityImageView.tintColor = .secondaryLabel

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

        avatarImageView.layer.cornerRadius = .avatarDimension / 2
        avatarImageView.clipsToBounds = true

        let avatarHeightConstraint = avatarImageView.heightAnchor.constraint(equalToConstant: .avatarDimension)

        avatarHeightConstraint.priority = .justBelowMax

        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.addSubview(avatarButton)
        avatarImageView.isUserInteractionEnabled = true
        avatarButton.setBackgroundImage(.highlightedButtonBackground, for: .highlighted)

        avatarButton.addAction(
            UIAction { [weak self] _ in self?.statusConfiguration.viewModel.accountSelected() },
            for: .touchUpInside)

        for view in [inReplyToView, hasReplyFollowingView] {
            addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = .opaqueSeparator
            view.widthAnchor.constraint(equalToConstant: .hairline).isActive = true
        }

        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: .avatarDimension),
            avatarHeightConstraint,
            sideStackView.widthAnchor.constraint(equalToConstant: .avatarDimension),
            infoIcon.centerYAnchor.constraint(equalTo: infoLabel.centerYAnchor),
            avatarButton.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            avatarButton.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            avatarButton.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
            avatarButton.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor),
            contextParentTimeApplicationStackView.heightAnchor.constraint(
                greaterThanOrEqualToConstant: .minimumButtonDimension / 2),
            interactionsStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: .minimumButtonDimension)
        ])
    }

    func applyStatusConfiguration() {
        let viewModel = statusConfiguration.viewModel
        let isContextParent = viewModel.configuration.isContextParent
        let mutableDisplayName = NSMutableAttributedString(string: viewModel.displayName)
        let isAuthenticated = viewModel.identityContext.identity.authenticated
            && !viewModel.identityContext.identity.pending

        menuButton.menu = menu(viewModel: viewModel)

        avatarImageView.kf.setImage(with: viewModel.avatarURL)

        sideStackView.isHidden = isContextParent
        avatarImageView.removeFromSuperview()

        if isContextParent {
            nameAccountContainerStackView.insertArrangedSubview(avatarImageView, at: 0)
        } else {
            sideStackView.insertArrangedSubview(avatarImageView, at: 1)
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
            infoLabel.attributedText = "status.reblogged-by".localizedBolding(
                displayName: viewModel.rebloggedByDisplayName,
                emojis: viewModel.rebloggedByDisplayNameEmojis,
                label: infoLabel)
            infoIcon.image = UIImage(
                systemName: "arrow.2.squarepath",
                withConfiguration: UIImage.SymbolConfiguration(scale: .small))
            infoLabel.isHidden = false
            infoIcon.isHidden = false
        } else if viewModel.configuration.isPinned {
            let pinnedText: String

            switch viewModel.identityContext.appPreferences.statusWord {
            case .toot:
                pinnedText = NSLocalizedString("status.pinned.toot", comment: "")
            case .post:
                pinnedText = NSLocalizedString("status.pinned.post", comment: "")
            }

            infoLabel.text = pinnedText
            infoIcon.image = UIImage(
                systemName: "pin",
                withConfiguration: UIImage.SymbolConfiguration(scale: .small))
            infoLabel.isHidden = false
            infoIcon.isHidden = false
        } else {
            infoLabel.isHidden = true
            infoIcon.isHidden = true
        }

        mutableDisplayName.insert(emojis: viewModel.displayNameEmojis, view: displayNameLabel)
        mutableDisplayName.resizeAttachments(toLineHeight: displayNameLabel.font.lineHeight)
        displayNameLabel.attributedText = mutableDisplayName

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

        accountLabel.text = viewModel.accountName
        timeLabel.text = viewModel.time
        timeLabel.isHidden = isContextParent

        bodyView.viewModel = viewModel

        contextParentTimeLabel.text = viewModel.contextParentTime
        visibilityImageView.image = UIImage(systemName: viewModel.visibility.systemImageName)
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
                    greaterThanOrEqualToConstant: .minimumButtonDimension / 2).isActive = true
            }
        }

        setButtonImages(scale: isContextParent ? .medium : .small)

        replyButton.setCountTitle(count: viewModel.repliesCount, isContextParent: isContextParent)
        replyButton.isEnabled = isAuthenticated

        if viewModel.identityContext.appPreferences.showReblogAndFavoriteCounts || isContextParent {
            reblogButton.setCountTitle(count: viewModel.reblogsCount, isContextParent: isContextParent)
            favoriteButton.setCountTitle(count: viewModel.favoritesCount, isContextParent: isContextParent)
        } else {
            reblogButton.setTitle(nil, for: .normal)
            favoriteButton.setTitle(nil, for: .normal)
        }

        setReblogButtonColor(reblogged: viewModel.reblogged)
        reblogButton.isEnabled = viewModel.canBeReblogged && isAuthenticated

        setFavoriteButtonColor(favorited: viewModel.favorited)
        favoriteButton.isEnabled = isAuthenticated

        shareButton.tag = viewModel.sharingURL?.hashValue ?? 0

        menuButton.isEnabled = isAuthenticated
    }
    // swiftlint:enable function_body_length

    func menu(viewModel: StatusViewModel) -> UIMenu {
        var menuItems = [
            UIAction(
                title: viewModel.bookmarked
                    ? NSLocalizedString("status.unbookmark", comment: "")
                    : NSLocalizedString("status.bookmark", comment: ""),
                image: UIImage(systemName: "bookmark")) { _ in
                viewModel.toggleBookmarked()
            }
        ]

        if let pinned = viewModel.pinned {
            menuItems.append(UIAction(
                title: pinned
                    ? NSLocalizedString("status.unpin", comment: "")
                    : NSLocalizedString("status.pin", comment: ""),
                image: UIImage(systemName: "pin")) { _ in
                viewModel.togglePinned()
            })
        }

        if viewModel.isMine {
            menuItems += [
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
        } else {
            menuItems.append(UIAction(
                title: NSLocalizedString("report", comment: ""),
                image: UIImage(systemName: "flag"),
                attributes: .destructive) { _ in
                viewModel.reportStatus()
            })
        }

        return UIMenu(children: menuItems)
    }

    func setButtonImages(scale: UIImage.SymbolScale) {
        replyButton.setImage(UIImage(systemName: "bubble.right",
                                     withConfiguration: UIImage.SymbolConfiguration(scale: scale)), for: .normal)
        reblogButton.setImage(UIImage(systemName: "arrow.2.squarepath",
                                      withConfiguration: UIImage.SymbolConfiguration(scale: scale)), for: .normal)
        favoriteButton.setImage(UIImage(systemName: statusConfiguration.viewModel.favorited ? "star.fill" : "star",
                                        withConfiguration: UIImage.SymbolConfiguration(scale: scale)), for: .normal)
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up",
                                     withConfiguration: UIImage.SymbolConfiguration(scale: scale)), for: .normal)
        menuButton.setImage(UIImage(systemName: "ellipsis",
                                    withConfiguration: UIImage.SymbolConfiguration(scale: scale)), for: .normal)
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
    }

    func setFavoriteButtonColor(favorited: Bool) {
        let favoriteColor: UIColor = favorited ? .systemYellow : .secondaryLabel

        favoriteButton.tintColor = favoriteColor
        favoriteButton.setTitleColor(favoriteColor, for: .normal)
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
}

private extension UIButton {
    func setCountTitle(count: Int, isContextParent: Bool) {
        setTitle((isContextParent || count == 0) ? nil : String(count), for: .normal)
    }
}
// swiftlint:enable file_length
