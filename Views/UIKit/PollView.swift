// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Mastodon
import UIKit
import ViewModels

final class PollView: UIView {
    private let stackView = UIStackView()
    private let bottomStackView = UIStackView()
    private let voteButton = CapsuleButton()
    private let refreshButton = UIButton(type: .system)
    private let refreshDividerLabel = UILabel()
    private let votesCountLabel = UILabel()
    private let votesCountDividerLabel = UILabel()
    private let expiryLabel = UILabel()
    private var selectionCancellable: AnyCancellable?

    var viewModel: StatusViewModel? {
        didSet {
            for view in stackView.arrangedSubviews {
                stackView.removeArrangedSubview(view)
                view.removeFromSuperview()
            }

            guard let viewModel = viewModel else {
                selectionCancellable = nil

                return
            }

            let accessibilityAttributedLabel = NSMutableAttributedString(
                string: NSLocalizedString("status.poll.accessibility-label", comment: ""))

            if !viewModel.isPollExpired, !viewModel.hasVotedInPoll {
                for (index, option) in viewModel.pollOptions.enumerated() {
                    let button = PollOptionButton(
                        title: option.title,
                        emojis: viewModel.pollEmojis,
                        multipleSelection: viewModel.isPollMultipleSelection,
                        identityContext: viewModel.identityContext)

                    button.button.addAction(
                        UIAction { _ in
                            if viewModel.pollOptionSelections.contains(index) {
                                viewModel.pollOptionSelections.remove(index)
                            } else if viewModel.isPollMultipleSelection {
                                viewModel.pollOptionSelections.insert(index)
                            } else {
                                viewModel.pollOptionSelections = [index]
                            }
                        },
                        for: .touchUpInside)

                    stackView.addArrangedSubview(button)
                }
            } else {
                for (index, option) in viewModel.pollOptions.enumerated() {
                    let resultView = PollResultView(
                        option: option,
                        emojis: viewModel.pollEmojis,
                        selected: viewModel.pollOwnVotes.contains(index),
                        multipleSelection: viewModel.isPollMultipleSelection,
                        votersCount: viewModel.pollVotersCount,
                        identityContext: viewModel.identityContext)

                    stackView.addArrangedSubview(resultView)
                }
            }

            for (index, view) in stackView.arrangedSubviews.enumerated() {
                var title: NSAttributedString?
                var percent: String?
                let indexLabel = String.localizedStringWithFormat(
                    NSLocalizedString("status.poll.option-%ld", comment: ""),
                    index + 1)

                if let optionView = view as? PollOptionButton,
                   let attributedTitle = optionView.button.accessibilityAttributedLabel {
                    title = attributedTitle

                    let optionAccessibilityAttributedLabel = NSMutableAttributedString(string: indexLabel)

                    if viewModel.isPollMultipleSelection {
                        optionAccessibilityAttributedLabel.appendWithSeparator(
                            NSLocalizedString("compose.poll.accessibility.multiple-choices-allowed", comment: ""))
                    }

                    optionAccessibilityAttributedLabel.appendWithSeparator(attributedTitle)
                    optionView.accessibilityAttributedLabel = optionAccessibilityAttributedLabel
                } else if let resultView = view as? PollResultView {
                    title = resultView.titleLabel.attributedText
                    percent = resultView.percentLabel.text
                }

                guard let presentTitle = title else { continue }

                accessibilityAttributedLabel.appendWithSeparator(indexLabel)
                accessibilityAttributedLabel.appendWithSeparator(presentTitle)

                if let percent = percent {
                    accessibilityAttributedLabel.appendWithSeparator(percent)
                }
            }

            if !viewModel.isPollExpired, !viewModel.hasVotedInPoll {
                stackView.addArrangedSubview(voteButton)

                selectionCancellable = viewModel.$pollOptionSelections.sink { [weak self] in
                    guard let self = self else { return }

                    for (index, view) in self.stackView.arrangedSubviews.enumerated() {
                        (view as? PollOptionButton)?.isSelected = $0.contains(index)
                    }

                    self.voteButton.isEnabled = !$0.isEmpty
                }
            } else {
                selectionCancellable = nil
            }

            stackView.addArrangedSubview(bottomStackView)

            let votesCount = String.localizedStringWithFormat(
                NSLocalizedString("status.poll.participation-count", comment: ""),
                viewModel.pollVotersCount)

            votesCountLabel.text = votesCount
            votesCountLabel.isAccessibilityElement = true
            votesCountLabel.accessibilityLabel = votesCountLabel.text
            accessibilityAttributedLabel.appendWithSeparator(votesCount)

            if !viewModel.isPollExpired, let pollTimeLeft = viewModel.pollTimeLeft {
                expiryLabel.text = String.localizedStringWithFormat(
                    NSLocalizedString("status.poll.time-left", comment: ""),
                    pollTimeLeft)
                refreshButton.isHidden = false
                accessibilityCustomActions =
                    [UIAccessibilityCustomAction(
                        name: NSLocalizedString("status.poll.refresh", comment: "")) { [weak self] _ in
                        self?.viewModel?.refreshPoll()

                        return true
                    }]
            } else {
                expiryLabel.text = NSLocalizedString("status.poll.closed", comment: "")
                refreshButton.isHidden = true
                accessibilityCustomActions = nil
            }

            expiryLabel.isAccessibilityElement = true
            expiryLabel.accessibilityLabel = expiryLabel.text

            if let expiry = expiryLabel.text {
                accessibilityAttributedLabel.appendWithSeparator(expiry)
            }

            refreshDividerLabel.isHidden = refreshButton.isHidden

            self.accessibilityAttributedLabel = accessibilityAttributedLabel
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
}

extension PollView {
    static func estimatedHeight(width: CGFloat,
                                identityContext: IdentityContext,
                                status: Status,
                                configuration: CollectionItem.StatusConfiguration) -> CGFloat {
        if let poll = status.displayStatus.poll {
            var height: CGFloat = 0
            let open = !poll.expired && !poll.voted

            for option in poll.options {
                height += open ? PollOptionButton.estimatedHeight(width: width, title: option.title)
                    : PollResultView.estimatedHeight(width: width, title: option.title)
                height += .defaultSpacing
            }

            if open {
                height += .minimumButtonDimension + .defaultSpacing
            }

            height += .minimumButtonDimension / 2

            return height
        } else {
            return 0
        }
    }
}

private extension PollView {
    func initialSetup() {
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = .defaultSpacing

        voteButton.setTitle(NSLocalizedString("status.poll.vote", comment: ""), for: .normal)
        voteButton.addAction(UIAction { [weak self] _ in self?.viewModel?.vote() }, for: .touchUpInside)

        bottomStackView.spacing = .compactSpacing

        bottomStackView.addArrangedSubview(refreshButton)
        refreshButton.titleLabel?.font = .preferredFont(forTextStyle: .caption1)
        refreshButton.titleLabel?.adjustsFontForContentSizeCategory = true
        refreshButton.setTitle(NSLocalizedString("status.poll.refresh", comment: ""), for: .normal)
        refreshButton.addAction(UIAction { [weak self] _ in self?.viewModel?.refreshPoll() }, for: .touchUpInside)

        for label in [refreshDividerLabel, votesCountLabel, votesCountDividerLabel, expiryLabel] {
            bottomStackView.addArrangedSubview(label)
            label.font = .preferredFont(forTextStyle: .caption1)
            label.textColor = .secondaryLabel
            label.adjustsFontForContentSizeCategory = true
        }

        refreshDividerLabel.text = "•"
        votesCountDividerLabel.text = "•"

        bottomStackView.addArrangedSubview(UIView())

        let refreshButtonHeightConstraint = refreshButton.heightAnchor.constraint(
            equalToConstant: .minimumButtonDimension / 2)

        refreshButtonHeightConstraint.priority = .justBelowMax

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            refreshButtonHeightConstraint
        ])
    }
}
