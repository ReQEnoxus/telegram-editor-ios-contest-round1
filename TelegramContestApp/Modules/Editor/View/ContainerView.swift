//
//  ContainerView.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 24.10.2022.
//

import UIKit

protocol ContainerView: UIView {
    associatedtype Media
    
    func updateMedia(with media: Media)
}
