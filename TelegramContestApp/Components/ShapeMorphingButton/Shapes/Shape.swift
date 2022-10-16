//
//  Shape.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 15.10.2022.
//

import CoreGraphics
import UIKit

protocol Shape {
    var strokeColor: CGColor? { get }
    var fillColor: CGColor? { get }
    var lineCap: CAShapeLayerLineCap { get }
    
    func draw(in bounds: CGRect) -> UIBezierPath
    func lineWidth(for bounds: CGRect) -> CGFloat
}
