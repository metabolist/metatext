// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import UIKit
import ViewModels

final class TimelinesTitleView: UIControl {
    let timelines: [Timeline]
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let imageView = UIImageView()
    private let chevronImageView = UIImageView(image: TimelinesTitleView.closedImage)
    private let identification: Identification

    @Published var selectedTimeline: Timeline {
        didSet { applyTimelineSelection() }
    }

    init(timelines: [Timeline], identification: Identification) {
        self.timelines = timelines
        self.identification = identification

        guard let timeline = timelines.first else {
            fatalError("TimelinesTitleView must be initialized with a non-empty timelines array")
        }

        selectedTimeline = timeline

        super.init(frame: .zero)

        accessibilityTraits = .button
        isAccessibilityElement = true
        showsMenuAsPrimaryAction = true
        isContextMenuInteractionEnabled = true

        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.tintColor = .label

        addSubview(chevronImageView)
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.setContentHuggingPriority(.required, for: .horizontal)

        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.5
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        addSubview(subtitleLabel)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.font = .preferredFont(forTextStyle: .caption2)
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.textAlignment = .center
        subtitleLabel.minimumScaleFactor = 0.5
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.setContentHuggingPriority(.required, for: .vertical)
        subtitleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        subtitleLabel.setContentCompressionResistancePriority(.justBelowMax, for: .vertical)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            imageView.topAnchor.constraint(equalTo: titleLabel.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: .compactSpacing),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            chevronImageView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: .defaultSpacing),
            chevronImageView.topAnchor.constraint(equalTo: titleLabel.topAnchor),
            chevronImageView.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            chevronImageView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        applyTimelineSelection()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? Self.highlightedAlpha : 1
        }
    }

    override func menuAttachmentPoint(for configuration: UIContextMenuConfiguration) -> CGPoint {
        CGPoint(x: (bounds.width - .systemMenuWidth) / 2 + .systemMenuInset, y: bounds.maxY + .compactSpacing)
    }

    override func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self = self else { return nil }

            return UIMenu(children: self.timelines.map { timeline in
                UIAction(
                    title: timeline.title,
                    image: UIImage(systemName: timeline.systemImageName),
                    attributes: timeline == self.selectedTimeline ? .disabled : [],
                    state: timeline == self.selectedTimeline ? .on : .off) { _ in
                    self.selectedTimeline = timeline
                }
            })
        }
    }

    override func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        willDisplayMenuFor configuration: UIContextMenuConfiguration,
        animator: UIContextMenuInteractionAnimating?) {
        chevronImageView.image = Self.openImage
    }

    override func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        willEndFor configuration: UIContextMenuConfiguration,
        animator: UIContextMenuInteractionAnimating?) {
        chevronImageView.image = Self.closedImage
        alpha = 1 // system bug
    }
}

private extension TimelinesTitleView {
    static let highlightedAlpha: CGFloat = 0.5
    static let openImage = UIImage(
        systemName: "chevron.compact.up",
        withConfiguration: UIImage.SymbolConfiguration(scale: .small))
    static let closedImage = UIImage(
        systemName: "chevron.compact.down",
        withConfiguration: UIImage.SymbolConfiguration(scale: .small))
    func applyTimelineSelection() {
        imageView.image = UIImage(
            systemName: selectedTimeline.systemImageName,
            withConfiguration: UIImage.SymbolConfiguration(scale: .small))
        titleLabel.text = selectedTimeline.title
        subtitleLabel.text = selectedTimeline.subtitle(identification: identification)
    }
}
