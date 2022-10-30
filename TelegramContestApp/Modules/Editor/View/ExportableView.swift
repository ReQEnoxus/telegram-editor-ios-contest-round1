//
//  ExportableView.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 29.10.2022.
//

import UIKit

protocol ExportableView: UIView {
    // perform actions needed before exporting (i.e. remove frames for text)
    func prepare()
}
