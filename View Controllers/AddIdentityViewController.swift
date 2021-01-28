// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import Kingfisher
import Mastodon
import SafariServices
import SwiftUI
import ViewModels

final class AddIdentityViewController: UIViewController {
    private let viewModel: AddIdentityViewModel
    private let rootViewModel: RootViewModel
    private let displayWelcome: Bool
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let promptLabel = UILabel()
    private let urlTextField = UITextField()
    private let welcomeLabel = UILabel()
    private let instanceVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let instanceStackView = UIStackView()
    private let instanceTitleLabel = UILabel()
    private let instanceURLLabel = UILabel()
    private let instanceImageView = AnimatedImageView()
    private let logInButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView()
    private let joinButton = UIButton(type: .system)
    private let browseButton = UIButton(type: .system)
    private let whatIsMastodonButton = UIButton(type: .system)
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: AddIdentityViewModel, rootViewModel: RootViewModel, displayWelcome: Bool) {
        self.viewModel = viewModel
        self.rootViewModel = rootViewModel
        self.displayWelcome = displayWelcome

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViews()
        setupViewHierarchy()
        setupConstraints()
        setupViewModelBindings()
        initialDisplay()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)

        viewModel.refreshFilter()
    }
}

private extension AddIdentityViewController {
    static let whatIsMastodonURL = URL(string: "https://joinmastodon.org")!

    // swiftlint:disable:next function_body_length
    func configureViews() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 20
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing

        welcomeLabel.numberOfLines = 0
        welcomeLabel.textAlignment = .center
        welcomeLabel.adjustsFontForContentSizeCategory = true
        welcomeLabel.font = .preferredFont(forTextStyle: .largeTitle)
        welcomeLabel.text = NSLocalizedString("add-identity.welcome", comment: "")

        promptLabel.numberOfLines = 0
        promptLabel.textAlignment = .center
        promptLabel.adjustsFontForContentSizeCategory = true
        promptLabel.font = .preferredFont(forTextStyle: .callout)
        promptLabel.text = NSLocalizedString("add-identity.prompt", comment: "")

        urlTextField.borderStyle = .roundedRect
        urlTextField.textContentType = .URL
        urlTextField.autocapitalizationType = .none
        urlTextField.autocorrectionType = .no
        urlTextField.keyboardType = .URL
        urlTextField.placeholder = NSLocalizedString("add-identity.instance-url", comment: "")
        urlTextField.addAction(
            UIAction { [weak self] _ in self?.viewModel.urlFieldText = self?.urlTextField.text ?? "" },
            for: .editingChanged)

        logInButton.setTitle(NSLocalizedString("add-identity.log-in", comment: ""), for: .normal)
        logInButton.addAction(
            UIAction { [weak self] _ in self?.viewModel.logInTapped() },
            for: .touchUpInside)

        activityIndicator.hidesWhenStopped = true

        instanceVisualEffectView.translatesAutoresizingMaskIntoConstraints = false

        instanceStackView.translatesAutoresizingMaskIntoConstraints = false
        instanceStackView.axis = .vertical
        instanceStackView.spacing = .compactSpacing

        instanceTitleLabel.numberOfLines = 0
        instanceTitleLabel.textAlignment = .center
        instanceTitleLabel.adjustsFontForContentSizeCategory = true
        instanceTitleLabel.font = .preferredFont(forTextStyle: .headline)

        instanceURLLabel.numberOfLines = 0
        instanceURLLabel.textAlignment = .center
        instanceURLLabel.adjustsFontForContentSizeCategory = true
        instanceURLLabel.font = .preferredFont(forTextStyle: .subheadline)
        instanceURLLabel.textColor = .secondaryLabel

        instanceImageView.contentMode = .scaleAspectFill
        instanceImageView.layer.cornerRadius = .defaultCornerRadius
        instanceImageView.clipsToBounds = true
        instanceImageView.kf.indicatorType = .activity
        instanceImageView.isHidden = true

        joinButton.addAction(UIAction { [weak self] _ in self?.join() }, for: .touchUpInside)

        browseButton.setTitle(NSLocalizedString("add-identity.browse", comment: ""), for: .normal)
        browseButton.isHidden = true
        browseButton.addAction(
            UIAction { [weak self] _ in self?.viewModel.browseTapped() },
            for: .touchUpInside)

        whatIsMastodonButton.setTitle(NSLocalizedString("add-identity.what-is-mastodon", comment: ""), for: .normal)
        whatIsMastodonButton.addAction(
            UIAction { [weak self] _ in
                self?.present(SFSafariViewController(url: Self.whatIsMastodonURL), animated: true)
            },
            for: .touchUpInside)

        for button in [logInButton, browseButton, joinButton, whatIsMastodonButton] {
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            button.titleLabel?.font = .preferredFont(forTextStyle: .title3)
        }
    }

    func setupViewHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        stackView.addArrangedSubview(promptLabel)
        stackView.addArrangedSubview(urlTextField)
        stackView.addArrangedSubview(welcomeLabel)
        instanceStackView.addArrangedSubview(instanceTitleLabel)
        instanceStackView.addArrangedSubview(instanceURLLabel)
        instanceVisualEffectView.contentView.addSubview(instanceStackView)
        instanceImageView.addSubview(instanceVisualEffectView)
        stackView.addArrangedSubview(instanceImageView)
        stackView.addArrangedSubview(activityIndicator)
        stackView.addArrangedSubview(logInButton)
        stackView.addArrangedSubview(joinButton)
        stackView.addArrangedSubview(browseButton)
        stackView.addArrangedSubview(whatIsMastodonButton)
    }

    func setupConstraints() {
        let instanceImageViewWidthConstraint = instanceImageView.widthAnchor.constraint(
            equalTo: instanceImageView.heightAnchor, multiplier: 16 / 9)
        instanceImageViewWidthConstraint.priority = .justBelowMax

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: .defaultSpacing),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.readableContentGuide.widthAnchor),
            stackView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            instanceImageViewWidthConstraint,
            instanceVisualEffectView.leadingAnchor.constraint(equalTo: instanceImageView.leadingAnchor),
            instanceVisualEffectView.trailingAnchor.constraint(equalTo: instanceImageView.trailingAnchor),
            instanceVisualEffectView.bottomAnchor.constraint(equalTo: instanceImageView.bottomAnchor),
            instanceStackView.leadingAnchor.constraint(equalTo: instanceVisualEffectView.contentView.leadingAnchor),
            instanceStackView.topAnchor.constraint(equalTo: instanceVisualEffectView.contentView.topAnchor,
                                                   constant: .defaultSpacing),
            instanceStackView.trailingAnchor.constraint(equalTo: instanceVisualEffectView.contentView.trailingAnchor),
            instanceStackView.bottomAnchor.constraint(equalTo: instanceVisualEffectView.contentView.bottomAnchor,
                                                      constant: -.defaultSpacing)
        ])
    }

    func setupViewModelBindings() {
        viewModel.$loading.sink { [weak self] in
            guard let self = self else { return }

            if $0 {
                self.activityIndicator.startAnimating()
                self.logInButton.isHidden = true
                self.joinButton.isHidden = true
                self.browseButton.isHidden = true
                self.whatIsMastodonButton.isHidden = true
            } else {
                self.activityIndicator.stopAnimating()
                self.logInButton.isHidden = false
                self.joinButton.isHidden = !(self.viewModel.instance?.registrations ?? true)
                self.browseButton.isHidden = !self.viewModel.isPublicTimelineAvailable
                self.whatIsMastodonButton.isHidden = false
            }
        }
        .store(in: &cancellables)

        viewModel.$instance.combineLatest(viewModel.$isPublicTimelineAvailable)
            .sink { [weak self] in self?.configure(instance: $0, isPublicTimelineAvailable: $1) }
            .store(in: &cancellables)

        viewModel.$alertItem
            .compactMap { $0 }
            .sink { [weak self] in self?.present(alertItem: $0) }
            .store(in: &cancellables)

        // There is a situation adding an identity from secondary navigation in which
        // setting presentingSecondaryNavigation = false on the navigation view model
        // does not work and the old secondary navigation is presented over the new
        // main navigation. This is a hack to fix it.
        rootViewModel.$navigationViewModel.dropFirst()
            .sink { [weak self] _ in self?.dismiss(animated: true) }
            .store(in: &cancellables)
    }

    func initialDisplay() {
        if displayWelcome {
            welcomeLabel.alpha = 0
            promptLabel.alpha = 0
            urlTextField.alpha = 0
            logInButton.alpha = 0
            whatIsMastodonButton.alpha = 0

            UIView.animate(withDuration: .longAnimationDuration * 2) {
                self.welcomeLabel.alpha = 1
            } completion: { _ in
                UIView.animate(withDuration: .longAnimationDuration * 2) {
                    self.welcomeLabel.alpha = 0
                } completion: { _ in
                    self.welcomeLabel.isHidden = true
                    UIView.animate(withDuration: .longAnimationDuration) {
                        self.promptLabel.alpha = 1
                    } completion: { _ in
                        UIView.animate(withDuration: .longAnimationDuration) {
                            self.urlTextField.alpha = 1
                        } completion: { _ in
                            self.urlTextField.becomeFirstResponder()
                            UIView.animate(withDuration: .longAnimationDuration) {
                                self.logInButton.alpha = 1
                            } completion: { _ in
                                UIView.animate(withDuration: .longAnimationDuration) {
                                    self.whatIsMastodonButton.alpha = 1
                                }
                            }
                        }
                    }
                }
            }
        } else {
            welcomeLabel.isHidden = true
            whatIsMastodonButton.isHidden = true
            urlTextField.becomeFirstResponder()
        }
    }

    func configure(instance: Instance?, isPublicTimelineAvailable: Bool) {
        if let instance = instance {
            instanceTitleLabel.text = instance.title
            instanceURLLabel.text = instance.uri
            instanceImageView.kf.setImage(with: instance.thumbnail)
            instanceImageView.isHidden = false

            if instance.registrations {
                let joinButtonTitle: String

                if instance.approvalRequired {
                    joinButtonTitle = NSLocalizedString("add-identity.request-invite", comment: "")
                } else {
                    joinButtonTitle = NSLocalizedString("add-identity.join", comment: "")
                }

                joinButton.setTitle(joinButtonTitle, for: .normal)
                joinButton.isHidden = false
            } else {
                joinButton.isHidden = true
            }

            browseButton.isHidden = !isPublicTimelineAvailable
        } else {
            instanceImageView.isHidden = true
            joinButton.isHidden = true
            browseButton.isHidden = true
        }
    }

    func join() {
        guard let instance = viewModel.instance, let url = viewModel.url else { return }

        let registrationViewModel = viewModel.registrationViewModel(instance: instance, url: url)
        let registrationView = RegistrationView(viewModel: registrationViewModel)
        let registrationViewController = UIHostingController(rootView: registrationView)

        show(registrationViewController, sender: self)
    }
}
