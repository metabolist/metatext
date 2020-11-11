// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import UIKit

final class AccountFieldView: UIView {
    let nameLabel = UILabel()
    let valueTextView = TouchFallthroughTextView()

    // swiftlint:disable:next function_body_length
    init(name: String, value: NSAttributedString, verifiedAt: Date?, emoji: [Emoji]) {
        super.init(frame: .zero)

        backgroundColor = .systemBackground

        let nameBackgroundView = UIView()

        addSubview(nameBackgroundView)
        nameBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        nameBackgroundView.backgroundColor = .secondarySystemBackground

        let valueBackgroundView = UIView()

        addSubview(valueBackgroundView)
        valueBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        valueBackgroundView.backgroundColor = verifiedAt == nil
            ? .systemBackground
            : UIColor.systemGreen.withAlphaComponent(0.25)

        addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.numberOfLines = 0
        nameLabel.font = .preferredFont(forTextStyle: .headline)
        nameLabel.textAlignment = .center
        nameLabel.textColor = .secondaryLabel

        let mutableName = NSMutableAttributedString(string: name)

        mutableName.insert(emoji: emoji, view: nameLabel)
        mutableName.resizeAttachments(toLineHeight: nameLabel.font.lineHeight)
        nameLabel.attributedText = mutableName

        let dividerView = UIView()

        addSubview(dividerView)
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.backgroundColor = .separator

        addSubview(valueTextView)
        valueTextView.translatesAutoresizingMaskIntoConstraints = false
        valueTextView.isScrollEnabled = false
        valueTextView.backgroundColor = .clear

        if verifiedAt != nil {
            valueTextView.linkTextAttributes = [
                .foregroundColor: UIColor.systemGreen as Any,
                .underlineColor: UIColor.clear]
        }

        let valueFont = UIFont.preferredFont(forTextStyle: verifiedAt == nil ? .body : .headline)
        let mutableValue = NSMutableAttributedString(attributedString: value)
        let valueRange = NSRange(location: 0, length: mutableValue.length)

        mutableValue.removeAttribute(.font, range: valueRange)
        mutableValue.addAttributes(
            [.font: valueFont as Any,
             .foregroundColor: UIColor.label],
            range: valueRange)
        mutableValue.insert(emoji: emoji, view: valueTextView)
        mutableValue.resizeAttachments(toLineHeight: valueFont.lineHeight)

        valueTextView.attributedText = mutableValue
        valueTextView.textAlignment = .center

        let checkButton = UIButton()

        checkButton.setImage(
            UIImage(
                systemName: "checkmark",
                withConfiguration: UIImage.SymbolConfiguration(scale: .small)),
            for: .normal)

        addSubview(checkButton)
        checkButton.translatesAutoresizingMaskIntoConstraints = false
        checkButton.tintColor = .systemGreen
        checkButton.isHidden = verifiedAt == nil
        checkButton.showsMenuAsPrimaryAction = true

        if let verifiedAt = verifiedAt {
            checkButton.menu = UIMenu(
                title: String.localizedStringWithFormat(
                    NSLocalizedString("account.field.verified", comment: ""),
                    Self.dateFormatter.string(from: verifiedAt)),
                options: .displayInline,
                children: [UIAction(title: NSLocalizedString("ok", comment: "")) { _ in }])
        }

        let nameLabelBottomConstraint = nameLabel.bottomAnchor.constraint(
            equalTo: bottomAnchor,
            constant: -.defaultSpacing)
        let valueTextViewBottomConstraint = valueTextView.bottomAnchor.constraint(
            lessThanOrEqualTo: bottomAnchor,
            constant: -.defaultSpacing)

        for constraint in [nameLabelBottomConstraint, valueTextViewBottomConstraint] {
            constraint.priority = .justBelowMax
        }

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .defaultSpacing),
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: .defaultSpacing),
            nameLabelBottomConstraint,
            dividerView.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: .defaultSpacing),
            dividerView.topAnchor.constraint(equalTo: topAnchor),
            dividerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dividerView.widthAnchor.constraint(equalToConstant: .hairline),
            checkButton.leadingAnchor.constraint(equalTo: dividerView.trailingAnchor, constant: .defaultSpacing),
            valueTextView.leadingAnchor.constraint(
                equalTo: verifiedAt == nil ? dividerView.trailingAnchor : checkButton.trailingAnchor,
                constant: .defaultSpacing),
            valueTextView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: .defaultSpacing),
            valueTextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.defaultSpacing),
            valueTextViewBottomConstraint,
            nameLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1 / 3),
            checkButton.centerYAnchor.constraint(equalTo: valueTextView.centerYAnchor),
            valueTextView.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            nameBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            nameBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            nameBackgroundView.trailingAnchor.constraint(equalTo: dividerView.leadingAnchor),
            nameBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            valueBackgroundView.leadingAnchor.constraint(equalTo: dividerView.trailingAnchor),
            valueBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            valueBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            valueBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension AccountFieldView {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()

        formatter.dateStyle = .full

        return formatter
    }()
}
