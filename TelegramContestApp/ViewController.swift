//
//  ViewController.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 12.10.2022.
//

import UIKit

class ViewController: UIViewController {
        
    lazy var textView: LabelInputContainerView = {
        let container = LabelInputContainerView()
        
        container.labelTextView.text = "Давно выяснено, что при оценке дизайна и композиции читаемый текст мешает сосредоточиться. Lorem Ipsum используют потому, что тот обеспечивает более или менее стандартное заполнение шаблона"
        
        return container.forAutoLayout()
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
        
        textView.configure(
            with: LabelContainerViewConfiguration(
                labelConfiguration: LabelTextViewConfiguration(
                    supportedFonts: [
                        textView.labelTextView.font ?? .systemFont(ofSize: 14),
                        .systemFont(ofSize: 20, weight: .thin),
                        .systemFont(ofSize: 25, weight: .bold)
                    ]
                ),
                outlineInset: 16
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


