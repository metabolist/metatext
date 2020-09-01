// Copyright © 2020 Metabolist. All rights reserved.

import AVKit
import Kingfisher
import UIKit
import ViewModels

protocol StatusTableViewCellDelegate: class {
    func statusTableViewCellDidHaveShareButtonTapped(_ cell: StatusTableViewCell)
}

class StatusTableViewCell: UITableViewCell {
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
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var cardImageView: UIImageView!
    @IBOutlet weak var cardTitleLabel: UILabel!
    @IBOutlet weak var cardDescriptionLabel: UILabel!
    @IBOutlet weak var cardURLLabel: UILabel!
    @IBOutlet weak var cardButton: UIButton!
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

    weak var delegate: StatusTableViewCellDelegate?

    @IBOutlet private var separatorConstraints: [NSLayoutConstraint]!

    var viewModel: StatusViewModel? {
        didSet {
            guard let viewModel = viewModel else { return }

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

            if let cardURL = viewModel.cardURL {
                cardTitleLabel.text = viewModel.cardTitle
                cardDescriptionLabel.text = viewModel.cardDescription
                cardDescriptionLabel.isHidden = cardDescriptionLabel.text == ""
                    || cardDescriptionLabel.text == cardTitleLabel.text
                if
                    let host = cardURL.host, host.hasPrefix("www."),
                    let withoutWww = cardURL.host?.components(separatedBy: "www.").last {
                    cardURLLabel.text = withoutWww
                } else {
                    cardURLLabel.text = cardURL.host
                }

                if let cardImageURL = viewModel.cardImageURL {
                    cardImageView.isHidden = false
                    cardImageView.kf.setImage(with: cardImageURL)
                } else {
                    cardImageView.isHidden = true
                }
                cardView.isHidden = false
            } else {
                cardView.isHidden = true
            }

            sensitiveContentView.isHidden = !viewModel.shouldDisplaySensitiveContent

            inReplyToView.isHidden = !viewModel.isReplyInContext

            hasReplyFollowingView.isHidden = !viewModel.hasReplyFollowing
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        for constraint in separatorConstraints {
            constraint.constant = 1 / UIScreen.main.scale
        }

        avatarImageView.kf.indicatorType = .activity
        contextParentAvatarImageView.kf.indicatorType = .activity
        cardImageView.kf.indicatorType = .activity

        contentTextView.delegate = self

        let highlightedButtonBackgroundImage = UIColor(white: 0, alpha: 0.5).image()

        cardButton.setBackgroundImage(highlightedButtonBackgroundImage, for: .highlighted)
        avatarButton.setBackgroundImage(highlightedButtonBackgroundImage, for: .highlighted)
        contextParentAvatarButton.setBackgroundImage(highlightedButtonBackgroundImage, for: .highlighted)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        avatarImageView.kf.cancelDownloadTask()
        cardImageView.kf.cancelDownloadTask()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        for button: UIButton in [toggleSensitiveContentButton] where button.frame.height != 0 {
            button.layer.cornerRadius = button.frame.height / 2
        }

        if hasReplyFollowingView.isHidden {
            separatorInset.right = UIDevice.current.userInterfaceIdiom == .phone ? 0 : layoutMargins.right
        } else {
            separatorInset.right = .greatestFiniteMagnitude
        }

        separatorInset.left = UIDevice.current.userInterfaceIdiom == .phone ? 0 : layoutMargins.left
    }
}

extension StatusTableViewCell {
    @IBAction func avatarButtonTapped(_ sender: Any) {

    }

    @IBAction func toggleSensitiveContentButtonTapped(_ sender: Any) {

    }

    @IBAction func cardButtonTapped(_ sender: UIButton) {

    }

    @IBAction func replyButtonTapped(_ sender: UIButton) {

    }

    @IBAction func reblogButtonTapped(_ sender: UIButton) {

    }

    @IBAction func favoriteButtonTapped(_ sender: UIButton) {
        viewModel?.toggleFavorited()
    }

    @IBAction func actionsButtonTapped(_ sender: Any) {

    }

    @IBAction func shareButtonTapped(_ sender: Any) {
        delegate?.statusTableViewCellDidHaveShareButtonTapped(self)
    }

    @IBAction func applicationButtonTapped(_ sender: Any) {

    }

    @IBAction func contextParentRebloggedByButtonTapped(_ sender: Any) {

    }

    @IBAction func contextParentFavoritedByButtonTapped(_ sender: Any) {

    }
}

extension StatusTableViewCell: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction) -> Bool {
        switch interaction {
        case .invokeDefaultAction: print(URL); return false
        case .preview: return false
        case .presentActions: return false
        @unknown default: return false
        }
    }
}

private extension StatusTableViewCell {
    private static let defaultAspectRatioConstraintMultiplier: CGFloat = 4.0 / 3.0
    private static let hasReplyFollowingSeparatorInsets = UIEdgeInsets(
        top: 0,
        left: 0,
        bottom: 0,
        right: .greatestFiniteMagnitude)

    private func setReblogButtonColor(reblogged: Bool) {
        let reblogColor: UIColor = reblogged ? .systemGreen : .secondaryLabel
        let reblogButton: UIButton

        if viewModel?.isContextParent ?? false {
            reblogButton = contextParentReblogButton
        } else {
            reblogButton = self.reblogButton
        }

        reblogButton.tintColor = reblogColor
        reblogButton.setTitleColor(reblogColor, for: .normal)
    }

    private func setFavoriteButtonColor(favorited: Bool) {
        let favoriteColor: UIColor = favorited ? .systemYellow : .secondaryLabel
        let favoriteButton: UIButton
        let scale: UIImage.SymbolScale

        if viewModel?.isContextParent ?? false {
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
