// Copyright © 2020 Metabolist. All rights reserved.

import AVFoundation
import Combine
import Mastodon
import UIKit
import ViewModels

final class CompositionInputAccessoryView: UIView {
    let tagForInputView = UUID().hashValue
    let autocompleteSelections: AnyPublisher<String, Never>

    private let viewModel: CompositionViewModel
    private let parentViewModel: NewStatusViewModel
    private let toolbar = UIToolbar()
    private let autocompleteCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: CompositionInputAccessoryView.autocompleteLayout())
    private let autocompleteDataSource: AutocompleteDataSource
    private let autocompleteCollectionViewHeightConstraint: NSLayoutConstraint
    private let autocompleteSelectionsSubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: CompositionViewModel,
         parentViewModel: NewStatusViewModel,
         autocompleteQueryPublisher: AnyPublisher<String?, Never>) {
        self.viewModel = viewModel
        self.parentViewModel = parentViewModel
        autocompleteDataSource = AutocompleteDataSource(
            collectionView: autocompleteCollectionView,
            queryPublisher: autocompleteQueryPublisher,
            parentViewModel: parentViewModel)
        autocompleteCollectionViewHeightConstraint =
            autocompleteCollectionView.heightAnchor.constraint(equalToConstant: .hairline)
        autocompleteSelections = autocompleteSelectionsSubject.eraseToAnyPublisher()

        super.init(
            frame: .init(
                origin: .zero,
                size: .init(width: UIScreen.main.bounds.width, height: .minimumButtonDimension)))

        initialSetup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        layoutIfNeeded()
    }
}

private extension CompositionInputAccessoryView {
    static let autocompleteCollectionViewMaxHeight: CGFloat = 150

    var heightConstraint: NSLayoutConstraint? {
        superview?.constraints.first(where: { $0.identifier == "accessoryHeight" })
    }

    // swiftlint:disable:next function_body_length
    func initialSetup() {
        autoresizingMask = .flexibleHeight

        addSubview(autocompleteCollectionView)
        autocompleteCollectionView.translatesAutoresizingMaskIntoConstraints = false
        autocompleteCollectionView.alwaysBounceVertical = false
        autocompleteCollectionView.backgroundColor = .clear
        autocompleteCollectionView.layer.cornerRadius = .defaultCornerRadius
        autocompleteCollectionView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        autocompleteCollectionView.dataSource = autocompleteDataSource
        autocompleteCollectionView.delegate = self

        let autocompleteBackgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))

        autocompleteCollectionView.backgroundView = autocompleteBackgroundView

        addSubview(toolbar)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.setContentCompressionResistancePriority(.required, for: .vertical)

        NSLayoutConstraint.activate([
            autocompleteCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            autocompleteCollectionView.topAnchor.constraint(equalTo: topAnchor),
            autocompleteCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            autocompleteCollectionView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: bottomAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: .minimumButtonDimension),
            autocompleteCollectionViewHeightConstraint
        ])

        var attachmentActions = [
            UIAction(
                title: NSLocalizedString("compose.browse", comment: ""),
                image: UIImage(systemName: "ellipsis")) { [weak self] _ in
                guard let self = self else { return }

                self.parentViewModel.presentDocumentPicker(viewModel: self.viewModel)
            },
            UIAction(
                title: NSLocalizedString("compose.photo-library", comment: ""),
                image: UIImage(systemName: "rectangle.on.rectangle")) { [weak self] _ in
                guard let self = self else { return }

                self.parentViewModel.presentMediaPicker(viewModel: self.viewModel)
            }
        ]

        #if !IS_SHARE_EXTENSION
        attachmentActions.insert(UIAction(
            title: NSLocalizedString("compose.take-photo-or-video", comment: ""),
            image: UIImage(systemName: "camera.fill")) { [weak self] _ in
            guard let self = self else { return }

            self.parentViewModel.presentCamera(viewModel: self.viewModel)
        },
        at: 1)
        #endif

        let attachmentButton = UIBarButtonItem(
            image: UIImage(systemName: "paperclip"),
            menu: UIMenu(children: attachmentActions))

        attachmentButton.accessibilityLabel =
            NSLocalizedString("compose.attachments-button.accessibility-label", comment: "")

        let pollButton = UIBarButtonItem(
            image: UIImage(systemName: "chart.bar.xaxis"),
            primaryAction: UIAction { [weak self] _ in self?.viewModel.displayPoll.toggle() })

        pollButton.accessibilityLabel = NSLocalizedString("compose.poll-button.accessibility-label", comment: "")

        let visibilityButton = UIBarButtonItem(
            image: UIImage(systemName: parentViewModel.visibility.systemImageName),
            menu: visibilityMenu(selectedVisibility: parentViewModel.visibility))

        let contentWarningButton = UIBarButtonItem(
            title: NSLocalizedString("status.content-warning-abbreviation", comment: ""),
            primaryAction: UIAction { [weak self] _ in self?.viewModel.displayContentWarning.toggle() })

        viewModel.$displayContentWarning.sink {
            if $0 {
                contentWarningButton.accessibilityHint =
                    NSLocalizedString("compose.content-warning-button.remove", comment: "")
            } else {
                contentWarningButton.accessibilityHint =
                    NSLocalizedString("compose.content-warning-button.add", comment: "")
            }
        }
        .store(in: &cancellables)

        let emojiButton = UIBarButtonItem(
            image: UIImage(systemName: "face.smiling"),
            primaryAction: UIAction { [weak self] _ in
                guard let self = self else { return }

                self.parentViewModel.presentEmojiPicker(tag: self.tagForInputView)
            })

        emojiButton.accessibilityLabel = NSLocalizedString("compose.emoji-button", comment: "")

        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus.circle.fill"),
            primaryAction: UIAction { [weak self] _ in
                guard let self = self else { return }

                self.parentViewModel.insert(after: self.viewModel)
            })

        switch parentViewModel.identityContext.appPreferences.statusWord {
        case .toot:
            addButton.accessibilityLabel =
                NSLocalizedString("compose.add-button-accessibility-label.toot", comment: "")
        case .post:
            addButton.accessibilityLabel =
                NSLocalizedString("compose.add-button-accessibility-label.post", comment: "")
        }

        let charactersBarItem = UIBarButtonItem()

        charactersBarItem.isEnabled = false

        toolbar.items = [
            attachmentButton,
            UIBarButtonItem.fixedSpace(.defaultSpacing),
            pollButton,
            UIBarButtonItem.fixedSpace(.defaultSpacing),
            visibilityButton,
            UIBarButtonItem.fixedSpace(.defaultSpacing),
            contentWarningButton,
            UIBarButtonItem.fixedSpace(.defaultSpacing),
            emojiButton,
            UIBarButtonItem.flexibleSpace(),
            charactersBarItem,
            UIBarButtonItem.fixedSpace(.defaultSpacing),
            addButton]

        viewModel.$canAddAttachment
            .sink { attachmentButton.isEnabled = $0 }
            .store(in: &cancellables)

        viewModel.$attachmentViewModels
            .combineLatest(viewModel.$attachmentUpload)
            .sink { pollButton.isEnabled = $0.isEmpty && $1 == nil }
            .store(in: &cancellables)

        viewModel.$remainingCharacters.sink {
            charactersBarItem.title = String($0)
            charactersBarItem.setTitleTextAttributes(
                [.foregroundColor: $0 < 0 ? UIColor.systemRed : UIColor.label],
                for: .disabled)
            charactersBarItem.accessibilityHint = String.localizedStringWithFormat(
                NSLocalizedString("compose.characters-remaining-accessibility-label-%ld", comment: ""),
                $0)
        }
        .store(in: &cancellables)

        viewModel.$isPostable
            .sink { addButton.isEnabled = $0 }
            .store(in: &cancellables)

        self.autocompleteCollectionView.publisher(for: \.contentSize)
            .map(\.height)
            .removeDuplicates()
            .throttle(for: .seconds(TimeInterval.shortAnimationDuration), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] height in
                UIView.animate(withDuration: .zeroIfReduceMotion(.shortAnimationDuration)) {
                    self?.setAutocompleteCollectionViewHeight(height)
                }
            }
            .store(in: &cancellables)

        parentViewModel.$visibility
            .sink { [weak self] in
                visibilityButton.image = UIImage(systemName: $0.systemImageName)
                visibilityButton.menu = self?.visibilityMenu(selectedVisibility: $0)
                visibilityButton.accessibilityLabel = String.localizedStringWithFormat(
                    NSLocalizedString("compose.visibility-button.accessibility-label-%@", comment: ""),
                    $0.title ?? "")
            }
            .store(in: &cancellables)
    }
}

extension CompositionInputAccessoryView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        guard let item = autocompleteDataSource.itemIdentifier(for: indexPath) else { return }

        switch item {
        case let .account(account):
            autocompleteSelectionsSubject.send("@".appending(account.acct))
        case let .tag(tag):
            autocompleteSelectionsSubject.send("#".appending(tag.name))
        case let .emoji(emoji):
            let escaped = emoji.applyingDefaultSkinTone(identityContext: parentViewModel.identityContext).escaped

            autocompleteSelectionsSubject.send(escaped)
            autocompleteDataSource.updateUse(emoji: emoji)
        }

        UISelectionFeedbackGenerator().selectionChanged()

        // To dismiss without waiting for the throttle
        UIView.animate(withDuration: .zeroIfReduceMotion(.shortAnimationDuration)) {
            self.setAutocompleteCollectionViewHeight(.hairline)
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        guard let item = autocompleteDataSource.itemIdentifier(for: indexPath),
              case let .emoji(emojiItem) = item,
              case let .system(emoji, _) = emojiItem,
              !emoji.skinToneVariations.isEmpty
        else { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: ([emoji] + emoji.skinToneVariations).map { skinToneVariation in
                UIAction(title: skinToneVariation.emoji) { [weak self] _ in
                    self?.autocompleteSelectionsSubject.send(skinToneVariation.emoji)
                    self?.autocompleteDataSource.updateUse(emoji: emojiItem)
                }
            })
        }
    }
}

private extension CompositionInputAccessoryView {
    static func autocompleteLayout() -> UICollectionViewLayout {
        var listConfig = UICollectionLayoutListConfiguration(appearance: .plain)

        listConfig.backgroundColor = .clear

        return UICollectionViewCompositionalLayout { index, environment -> NSCollectionLayoutSection? in
            guard let autocompleteSection = AutocompleteSection(rawValue: index) else { return nil }

            switch autocompleteSection {
            case .search:
                return .list(using: listConfig, layoutEnvironment: environment)
            case .emoji:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(.minimumButtonDimension),
                    heightDimension: .absolute(.minimumButtonDimension))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)

                section.interGroupSpacing = .defaultSpacing
                section.orthogonalScrollingBehavior = .continuous
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: .compactSpacing,
                    leading: .compactSpacing,
                    bottom: .compactSpacing,
                    trailing: .compactSpacing)

                return section
            }
        }
    }

    func visibilityMenu(selectedVisibility: Status.Visibility) -> UIMenu {
        UIMenu(children: Status.Visibility.allCasesExceptUnknown.reversed().map { visibility in
            UIAction(
                title: visibility.title ?? "",
                image: UIImage(systemName: visibility.systemImageName),
                discoverabilityTitle: visibility.description,
                state: visibility == selectedVisibility ? .on : .off) { [weak self] _ in
                self?.parentViewModel.visibility = visibility
            }
        })
    }

    func setAutocompleteCollectionViewHeight(_ height: CGFloat) {
        let autocompleteCollectionViewHeight = min(max(height, .hairline), Self.autocompleteCollectionViewMaxHeight)

        autocompleteCollectionViewHeightConstraint.constant = autocompleteCollectionViewHeight
        autocompleteCollectionView.alpha = autocompleteCollectionViewHeightConstraint.constant == .hairline ? 0 : 1

        heightConstraint?.constant = .minimumButtonDimension + autocompleteCollectionViewHeight
        updateConstraints()
        superview?.superview?.layoutIfNeeded()
    }
}
