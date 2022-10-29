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
    
    private let button = SweepingButton().forAutoLayout()
    
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
        
        textView.labelTextView.font = .systemFont(ofSize: 25, weight: .bold)
//        textView.configure(
//            with: LabelContainerViewConfiguration(
//                labelConfiguration: LabelTextViewConfiguration(
//                    supportedFonts: [
//                        textView.labelTextView.font ?? .systemFont(ofSize: 14),
//                        .systemFont(ofSize: 25, weight: .thin),
//                    ]
//                ),
//                outlineInset: 24
//            )
//        )
        button.setTitle("Allow editing", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
    }
    
    private func commonInit() {
        addSubviews()
        makeConstraints()
    }
    
    private func addSubviews() {
        view.addSubview(button)
//        view.addSubview(textView)
    }
    
    private func makeConstraints() {
        NSLayoutConstraint.activate(
            [
                textView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                textView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
                textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
//                textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
                textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
//                textView.heightAnchor.constraint(equalToConstant: 60)
                
                button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
                button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
                button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
            ]
        )
    }
}


