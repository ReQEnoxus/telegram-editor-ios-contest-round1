//
//  ViewController.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 12.10.2022.
//

import UIKit

class ViewController: UIViewController {
    
    lazy var keyboardAccessoryView: FontCustomizationAccessoryView = FontCustomizationAccessoryView()
    
    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        textView.textContainer.lineFragmentPadding = .zero
        textView.contentMode = .topLeft
        textView.textDragInteraction?.isEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.keyboardAppearance = .dark
        textView.inputAccessoryView = keyboardAccessoryView
        
        return textView
    }()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray5
        
        keyboardAccessoryView.configure(
            with: FontCustomizationAccessoryViewConfiguration(
                fontItems: [
                    FontCustomizationAccessoryViewConfiguration.FontItem(
                        font: .systemFont(ofSize: 17, weight: .regular),
                        name: "System Regular",
                        isSelected: false
                    ),
                    FontCustomizationAccessoryViewConfiguration.FontItem(
                        font: .systemFont(ofSize: 17, weight: .bold),
                        name: "System Bold",
                        isSelected: false
                    )
                ],
                fontDidChange: { font in
                    print("!! \(font.name) selected")
                }
            )
        )
    }
    
    private func commonInit() {
        addSubviews()
        makeConstraints()
    }
    
    private func addSubviews() {
        view.addSubview(textView)
    }
    
    private func makeConstraints() {
        NSLayoutConstraint.activate(
            [
                textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
                textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
                textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
                textView.heightAnchor.constraint(equalToConstant: 60)
            ]
        )
    }
}


