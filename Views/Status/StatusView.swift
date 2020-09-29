// Copyright © 2020 Metabolist. All rights reserved.

import Kingfisher
import UIKit

class StatusView: UIView {
    @IBOutlet var baseView: UIView!
    @IBOutlet weak var metaIcon: UIImageView!
    @IBOutlet weak var metaLabel: UILabel!
    @IBOutlet weak var contentTextView: TouchFallthroughTextView!
    @IBOutlet weak var avatarButton: UIButton!
    @IBOutlet weak var avatarImageView: AnimatedImageView!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var accountLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var spoilerTextLabel: UILabel!
    @IBOutlet weak var toggleSensitiveContentButton: UIButton!
    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var reblogButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var attachmentsView: AttachmentsView!
    @IBOutlet weak var cardView: CardView!
    @IBOutlet weak var sensitiveContentView: UIStackView!
    @IBOutlet weak var hasReplyFollowingView: UIView!
    @IBOutlet weak var inReplyToView: UIView!
    @IBOutlet weak var avatarReplyContextView: UIView!
    @IBOutlet weak var nameDateView: UIStackView!
    @IBOutlet weak var contextParentAvatarNameView: UIStackView!
    @IBOutlet weak var contextParentAvatarImageView: AnimatedImageView!
    @IBOutlet weak var contextParentAvatarButton: UIButton!
    @IBOutlet weak var contextParentDisplayNameLabel: UILabel!
    @IBOutlet weak var contextParentAccountLabel: UILabel!
    @IBOutlet weak var actionButtonsView: UIStackView!
    @IBOutlet weak var contextParentReplyButton: UIButton!
    @IBOutlet weak var contextParentReblogButton: UIButton!
    @IBOutlet weak var contextParentFavoriteButton: UIButton!
    @IBOutlet weak var contextParentShareButton: UIButton!
    @IBOutlet weak var contextParentActionsButton: UIButton!
    @IBOutlet weak var contextParentTimeLabel: UILabel!
    @IBOutlet weak var timeApplicationDividerView: UILabel!
    @IBOutlet weak var applicationButton: UIButton!
    @IBOutlet weak var contextParentRebloggedByButton: UIButton!
    @IBOutlet weak var contextParentFavoritedByButton: UIButton!
    @IBOutlet weak var contextParentItems: UIStackView!
    @IBOutlet weak var contextParentRebloggedByFavoritedByView: UIStackView!
    @IBOutlet weak var contextParentRebloggedByFavoritedBySeparator: UIView!

    private var statusConfiguration: StatusContentConfiguration
    @IBOutlet private var separatorConstraints: [NSLayoutConstraint]!

    init(configuration: StatusContentConfiguration) {
        self.statusConfiguration = configuration

        super.init(frame: .zero)

        initialSetup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        for button: UIButton in [toggleSensitiveContentButton] where button.frame.height != 0 {
            button.layer.cornerRadius = button.frame.height / 2
        }
    }
}

extension StatusView: UIContentView {
    var configuration: UIContentConfiguration {
        get { statusConfiguration }
        set {
            guard let statusConfiguration = newValue as? StatusContentConfiguration else { return }

            self.statusConfiguration = statusConfiguration

            avatarImageView.kf.cancelDownloadTask()
            contextParentAvatarImageView.kf.cancelDownloadTask()
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
    // swiftlint:disable function_body_length
    func initialSetup() {
        Bundle.main.loadNibNamed(String(describing: type(of: self)), owner: self, options: nil)

        addSubview(baseView)

        baseView.translatesAutoresizingMaskIntoConstraints = false
        baseView.backgroundColor = .clear

        NSLayoutConstraint.activate([
            baseView.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
            baseView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            baseView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            baseView.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor),
            // These have "Placeholder" checked in the xib file so they can
            // be set to go beyond the readable content guide
            inReplyToView.topAnchor.constraint(equalTo: topAnchor),
            hasReplyFollowingView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        for constraint in separatorConstraints {
            constraint.constant = 1 / UIScreen.main.scale
        }

        avatarImageView.kf.indicatorType = .activity
        contextParentAvatarImageView.kf.indicatorType = .activity

        contentTextView.delegate = self

        avatarButton.setBackgroundImage(.highlightedButtonBackground, for: .highlighted)
        contextParentAvatarButton.setBackgroundImage(.highlightedButtonBackground, for: .highlighted)

        let accountAction = UIAction { [weak self] _ in self?.statusConfiguration.viewModel.accountSelected() }

        avatarButton.addAction(accountAction, for: .touchUpInside)
        contextParentAvatarButton.addAction(accountAction, for: .touchUpInside)

        cardView.button.addAction(
            UIAction { [weak self] _ in
                guard
                    let viewModel = self?.statusConfiguration.viewModel,
                    let url = viewModel.cardViewModel?.url
                else { return }

                viewModel.urlSelected(url)
            },
            for: .touchUpInside)

        let favoriteAction = UIAction { [weak self] _ in self?.statusConfiguration.viewModel.toggleFavorited() }

        favoriteButton.addAction(favoriteAction, for: .touchUpInside)
        contextParentFavoriteButton.addAction(favoriteAction, for: .touchUpInside)

        shareButton.addAction(
            UIAction { [weak self] _ in self?.statusConfiguration.viewModel.shareStatus() },
            for: .touchUpInside)

        contextParentRebloggedByButton.addAction(
            UIAction { [weak self] _ in self?.statusConfiguration.viewModel.rebloggedBySelected() },
            for: .touchUpInside)

        contextParentFavoritedByButton.addAction(
            UIAction { [weak self] _ in self?.statusConfiguration.viewModel.favoritedBySelected() },
            for: .touchUpInside)

        applicationButton.addAction(
            UIAction { [weak self] _ in
                guard
                    let viewModel = self?.statusConfiguration.viewModel,
                    let url = viewModel.applicationURL
                else { return }

                viewModel.urlSelected(url)
            },
            for: .touchUpInside)

        applyStatusConfiguration()
    }

    func applyStatusConfiguration() {
        let viewModel = statusConfiguration.viewModel
        let mutableContent = NSMutableAttributedString(attributedString: viewModel.content)
        let mutableDisplayName = NSMutableAttributedString(string: viewModel.displayName)
        let mutableSpoilerText = NSMutableAttributedString(string: viewModel.spoilerText)
        let contentFont = UIFont.preferredFont(forTextStyle: viewModel.isContextParent ? .title3 : .callout)

        contentTextView.shouldFallthrough = !viewModel.isContextParent
        avatarReplyContextView.isHidden = viewModel.isContextParent
        nameDateView.isHidden = viewModel.isContextParent
        contextParentAvatarNameView.isHidden = !viewModel.isContextParent
        actionButtonsView.isHidden = viewModel.isContextParent
        contextParentItems.isHidden = !viewModel.isContextParent

        let avatarImageView: UIImageView
        let displayNameLabel: UILabel
        let accountLabel: UILabel

        if viewModel.isContextParent {
            avatarImageView = contextParentAvatarImageView
            displayNameLabel = contextParentDisplayNameLabel
            accountLabel = contextParentAccountLabel
        } else {
            avatarImageView = self.avatarImageView
            displayNameLabel = self.displayNameLabel
            accountLabel = self.accountLabel
        }

        let contentRange = NSRange(location: 0, length: mutableContent.length)
        mutableContent.removeAttribute(.font, range: contentRange)
        mutableContent.addAttributes(
            [.font: contentFont as Any,
             .foregroundColor: UIColor.label],
            range: contentRange)
        mutableContent.insert(emoji: viewModel.contentEmoji, view: contentTextView)
        mutableContent.resizeAttachments(toLineHeight: contentFont.lineHeight)
        contentTextView.attributedText = mutableContent
        contentTextView.isHidden = contentTextView.text == ""
        mutableDisplayName.insert(emoji: viewModel.displayNameEmoji, view: displayNameLabel)
        mutableDisplayName.resizeAttachments(toLineHeight: displayNameLabel.font.lineHeight)
        displayNameLabel.attributedText = mutableDisplayName
        mutableSpoilerText.insert(emoji: viewModel.contentEmoji, view: spoilerTextLabel)
        mutableSpoilerText.resizeAttachments(toLineHeight: spoilerTextLabel.font.lineHeight)
        spoilerTextLabel.attributedText = mutableSpoilerText
        spoilerTextLabel.isHidden = !viewModel.sensitive || spoilerTextLabel.text == ""
        toggleSensitiveContentButton.setTitle(
            viewModel.shouldDisplaySensitiveContent
                ? NSLocalizedString("status.show-less", comment: "")
                : NSLocalizedString("status.show-more", comment: ""),
            for: .normal)
        accountLabel.text = viewModel.accountName
        timeLabel.text = viewModel.time
        contextParentTimeLabel.text = viewModel.contextParentTime
        timeApplicationDividerView.isHidden = viewModel.applicationName == nil
        applicationButton.isHidden = viewModel.applicationName == nil
        applicationButton.setTitle(viewModel.applicationName, for: .normal)
        applicationButton.isEnabled = viewModel.applicationURL != nil
        avatarImageView.kf.setImage(with: viewModel.avatarURL)
        toggleSensitiveContentButton.isHidden = !viewModel.sensitive
        replyButton.setTitle(viewModel.repliesCount == 0 ? "" : String(viewModel.repliesCount), for: .normal)
        reblogButton.setTitle(viewModel.reblogsCount == 0 ? "" : String(viewModel.reblogsCount), for: .normal)
        setReblogButtonColor(reblogged: viewModel.reblogged)
        favoriteButton.setTitle(viewModel.favoritesCount == 0 ? "" : String(viewModel.favoritesCount), for: .normal)
        setFavoriteButtonColor(favorited: viewModel.favorited)

        reblogButton.isEnabled = viewModel.canBeReblogged
        contextParentReblogButton.isEnabled = viewModel.canBeReblogged

        let noReblogs = viewModel.reblogsCount == 0
        let noFavorites = viewModel.favoritesCount == 0
        let noInteractions = noReblogs && noFavorites

        setAttributedLocalizedTitle(
            button: contextParentRebloggedByButton,
            localizationKey: "status.reblogs-count",
            count: viewModel.reblogsCount)
        contextParentRebloggedByButton.isHidden = noReblogs
        setAttributedLocalizedTitle(
            button: contextParentFavoritedByButton,
            localizationKey: "status.favorites-count",
            count: viewModel.favoritesCount)
        contextParentFavoritedByButton.isHidden = noFavorites

        contextParentRebloggedByFavoritedByView.isHidden = noInteractions
        contextParentRebloggedByFavoritedBySeparator.isHidden = noInteractions

        if
            viewModel.isReblog {
            let metaText = String.localizedStringWithFormat(
                NSLocalizedString("status.reblogged-by", comment: ""),
                viewModel.rebloggedByDisplayName)
            let mutableMetaText = NSMutableAttributedString(string: metaText)
            mutableMetaText.insert(emoji: viewModel.rebloggedByDisplayNameEmoji, view: metaLabel)
            mutableMetaText.resizeAttachments(toLineHeight: metaLabel.font.lineHeight)
            metaLabel.attributedText = mutableMetaText
            metaIcon.image = UIImage(
                systemName: "arrow.2.squarepath",
                withConfiguration: UIImage.SymbolConfiguration(scale: .small))
            metaLabel.isHidden = false
            metaIcon.isHidden = false
        } else if viewModel.isPinned {
            metaLabel.text = NSLocalizedString("status.pinned-post", comment: "")
            metaIcon.image = UIImage(
                systemName: "pin",
                withConfiguration: UIImage.SymbolConfiguration(scale: .small))
            metaLabel.isHidden = false
            metaIcon.isHidden = false
        } else {
            metaLabel.isHidden = true
            metaIcon.isHidden = true
        }

        attachmentsView.isHidden = viewModel.attachmentViewModels.count == 0
        attachmentsView.attachmentViewModels = viewModel.attachmentViewModels
        setNeedsLayout()

        cardView.viewModel = viewModel.cardViewModel
        cardView.isHidden = viewModel.cardViewModel == nil

        sensitiveContentView.isHidden = !viewModel.shouldDisplaySensitiveContent

        inReplyToView.isHidden = !viewModel.isReplyInContext

        hasReplyFollowingView.isHidden = !viewModel.hasReplyFollowing
    }
    // swiftlint:enable function_body_length

    func setReblogButtonColor(reblogged: Bool) {
        let reblogColor: UIColor = reblogged ? .systemGreen : .secondaryLabel
        let reblogButton: UIButton

        if statusConfiguration.viewModel.isContextParent {
            reblogButton = contextParentReblogButton
        } else {
            reblogButton = self.reblogButton
        }

        reblogButton.tintColor = reblogColor
        reblogButton.setTitleColor(reblogColor, for: .normal)
    }

    func setFavoriteButtonColor(favorited: Bool) {
        let favoriteColor: UIColor = favorited ? .systemYellow : .secondaryLabel
        let favoriteButton: UIButton
        let scale: UIImage.SymbolScale

        if statusConfiguration.viewModel.isContextParent {
            favoriteButton = contextParentFavoriteButton
            scale = .medium
        } else {
            favoriteButton = self.favoriteButton
            scale = .small
        }

        favoriteButton.tintColor = favoriteColor
        favoriteButton.setTitleColor(favoriteColor, for: .normal)
        favoriteButton.setImage(UIImage(
                                    systemName: favorited ? "star.fill" : "star",
                                    withConfiguration: UIImage.SymbolConfiguration(scale: scale)),
                                for: .normal)
    }

    private func setAttributedLocalizedTitle(button: UIButton, localizationKey: String, count: Int) {
        let localizedTitle = String.localizedStringWithFormat(NSLocalizedString(localizationKey, comment: ""), count)

        button.setAttributedTitle(localizedTitle.countEmphasizedAttributedString(count: count), for: .normal)
        button.setAttributedTitle(
            localizedTitle.countEmphasizedAttributedString(count: count, highlighted: true),
            for: .highlighted)
    }
}
