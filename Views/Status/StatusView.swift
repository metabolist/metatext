// Copyright © 2020 Metabolist. All rights reserved.

import UIKit

class StatusView: UIView {
    private var statusConfiguration: StatusContentConfiguration

    private let content = TouchFallthroughTextView()

    init(configuration: StatusContentConfiguration) {
        self.statusConfiguration = configuration

        super.init(frame: .zero)

        setup()
        applyStatusConfiguration()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

private extension StatusView {
    func setup() {
        addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        content.isScrollEnabled = false
        content.isEditable = false
        content.backgroundColor = .clear
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            content.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor)
        ])
    }

    func applyStatusConfiguration() {
        let viewModel = statusConfiguration.viewModel
        let mutableContent = NSMutableAttributedString(attributedString: viewModel.content)
        let contentFont = UIFont.preferredFont(forTextStyle: viewModel.isContextParent ? .title3 : .callout)

        let contentRange = NSRange(location: 0, length: mutableContent.length)
        mutableContent.removeAttribute(.font, range: contentRange)
        mutableContent.addAttributes(
            [.font: contentFont as Any,
             .foregroundColor: UIColor.label],
            range: contentRange)
        mutableContent.insert(emoji: viewModel.contentEmoji, view: content)
        mutableContent.resizeAttachments(toLineHeight: contentFont.lineHeight)
        content.attributedText = mutableContent
//        content.isHidden = contentTextView.text == ""
    }
}
