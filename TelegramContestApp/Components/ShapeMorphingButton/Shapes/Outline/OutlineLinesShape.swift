//
//  OutlineLinesShape.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 17.10.2022.
//

import UIKit

struct OutlineLinesShape: Shape {
    let lineInfo: LabelTextView.LineInfo
    let outlineMode: OutlineMode
    let inset: CGFloat
    let radiusMultiplier: CGFloat
    let alignment: TextAlignment?
    
    internal init(
        lineInfo: LabelTextView.LineInfo,
        outlineMode: OutlineMode,
        inset: CGFloat,
        radiusMultiplier: CGFloat = 0.2,
        alignment: TextAlignment? = nil
    ) {
        self.lineInfo = lineInfo
        self.outlineMode = outlineMode
        self.inset = inset
        self.radiusMultiplier = radiusMultiplier
        self.alignment = alignment
    }
    
    var strokeColor: CGColor? {
        return UIColor.red.cgColor
    }
    
    var fillColor: CGColor? {
        switch outlineMode {
        case .solid(let color):
            return color.withAlphaComponent(.one).cgColor
        case .transparent(let color, let alphaComponent):
            return color.withAlphaComponent(alphaComponent).cgColor
        case .text, .none:
            return UIColor.clear.cgColor
        }
    }
    
    var lineCap: CAShapeLayerLineCap {
        return .butt
    }
    
    private var horizontalInset: CGFloat {
        return inset.half
    }
    
    func draw(in bounds: CGRect) -> UIBezierPath {
        let rects = realignLineFramgentRects(lineInfo: lineInfo)
        let path = buildPath(for: rects)
        return path
    }
    
    func lineWidth(for bounds: CGRect) -> CGFloat {
        return .zero
    }
    
    private func buildPath(for rects: [CGRect]) -> UIBezierPath {
        var path = UIBezierPath()
        guard !rects.isEmpty else { return path }
        let firstRect = rects[0]
        let lastRect = rects[rects.endIndex - 1]
        let radius = firstRect.height * radiusMultiplier
        path.move(
            to: CGPoint(
                x: firstRect.minX + radius,
                y: firstRect.minY
            )
        )
        path.addCurve(
            from: CGPoint(
                x: firstRect.minX + radius,
                y: firstRect.minY
            ),
            to: CGPoint(
                x: firstRect.minX,
                y: firstRect.minY + radius
            ),
            curveType: .leftCircle
        )
        path.addCurve(
            from: CGPoint(
                x: firstRect.minX,
                y: firstRect.minY + radius
            ),
            to: CGPoint(
                x: firstRect.origin.x,
                y: firstRect.maxY - radius
            )
        )

        rects.dropFirst().enumerated().forEach { index, nextRect in
            let currentRect = rects[index]
            path = pathByAppendingLeftStep(from: currentRect, to: nextRect, path: path, radius: radius)
        }
        path.addCurve(
            from: CGPoint(
                x: lastRect.minX,
                y: lastRect.maxY - radius
            ),
            to: CGPoint(
                x: lastRect.minX + radius,
                y: lastRect.maxY
            ),
            curveType: .leftCircle
        )
        path.addCurve(
            from: CGPoint(
                x: lastRect.minX + radius,
                y: lastRect.maxY
            ),
            to: CGPoint(
                x: lastRect.maxX - radius,
                y: lastRect.maxY
            )
        )
        path.addCurve(
            from: CGPoint(
                x: lastRect.maxX - radius,
                y: lastRect.maxY
            ),
            to: CGPoint(
                x: lastRect.maxX,
                y: lastRect.maxY - radius
            ),
            curveType: .rightCircle
        )
        path.addCurve(
            from: CGPoint(
                x: lastRect.maxX,
                y: lastRect.maxY - radius
            ),
            to: CGPoint(
                x: lastRect.maxX,
                y: lastRect.minY + radius
            )
        )
        let reversedRects = Array(rects.reversed())
        reversedRects.dropFirst().enumerated().forEach { index, nextRect in
            let currentRect = reversedRects[index]
            path = pathByAppendingRightStep(from: currentRect, to: nextRect, radius: radius, path: path)
        }
        path.addCurve(
            from: CGPoint(
                x: firstRect.maxX,
                y: firstRect.minY + radius
            ),
            to: CGPoint(
                x: firstRect.maxX - radius,
                y: firstRect.minY
            ),
            curveType: .rightCircle
        )
        path.addCurve(
            from: CGPoint(
                x: firstRect.maxX - radius,
                y: firstRect.minY
            ),
            to: CGPoint(
                x: firstRect.origin.x + radius,
                y: firstRect.origin.y
            )
        )
        

        return path
    }
    
    private func pathByAppendingLeftStep(from currentRect: CGRect, to nextRect: CGRect, path: UIBezierPath, radius: CGFloat) -> UIBezierPath {
        let diff = currentRect.minX - nextRect.minX
        
        if diff == .zero {
            // по левому краю совпадают
            path.addCurve(
                from: CGPoint(
                    x: currentRect.minX,
                    y: currentRect.maxY - radius
                ),
                to: CGPoint(
                    x: currentRect.minX,
                    y: currentRect.maxY
                )
            )
            path.addCurve(
                from: CGPoint(
                    x: currentRect.minX,
                    y: currentRect.maxY
                ),
                to: CGPoint(
                    x: currentRect.minX,
                    y: currentRect.maxY
                )
            )
            path.addCurve(
                from: CGPoint(
                    x: currentRect.minX,
                    y: currentRect.maxY
                ),
                to: CGPoint(
                    x: currentRect.minX,
                    y: nextRect.minY + radius
                )
            )
            path.addCurve(
                from: CGPoint(
                    x: currentRect.minX,
                    y: nextRect.minY + radius
                ),
                to: CGPoint(
                    x: currentRect.minX,
                    y: nextRect.maxY - radius
                )
            )
        } else if diff < .zero {
            // следующий находится правее
            path.addCurve(
                from: CGPoint(
                    x: currentRect.minX,
                    y: currentRect.maxY - radius
                ),
                to: CGPoint(
                    x: currentRect.minX + radius,
                    y: currentRect.maxY
                ),
                curveType: .leftCircle
            )
            path.addCurve(
                from: CGPoint(
                    x: currentRect.minX + radius,
                    y: currentRect.maxY
                ),
                to: CGPoint(
                    x: nextRect.minX - radius,
                    y: nextRect.minY
                )
            )
            path.addCurve(
                from: CGPoint(
                    x: nextRect.minX - radius,
                    y: nextRect.minY
                ),
                to: CGPoint(
                    x: nextRect.minX,
                    y: nextRect.minY + radius
                ),
                curveType: .rightCircle
            )
            path.addCurve(
                from: CGPoint(
                    x: nextRect.minX,
                    y: nextRect.minY + radius
                ),
                to: CGPoint(
                    x: nextRect.minX,
                    y: nextRect.maxY - radius
                )
            )
        } else {
            // следующий находится левее
            path.addCurve(
                from: CGPoint(
                    x: currentRect.minX,
                    y: currentRect.maxY - radius
                ),
                to: CGPoint(
                    x: currentRect.minX - radius,
                    y: currentRect.maxY
                ),
                curveType: .rightCircle
            )
            path.addCurve(
                from: CGPoint(
                    x: currentRect.minX - radius,
                    y: currentRect.maxY
                ),
                to: CGPoint(
                    x: nextRect.minX + radius,
                    y: nextRect.minY
                )
            )
            path.addCurve(
                from: CGPoint(
                    x: nextRect.minX + radius,
                    y: nextRect.minY
                ),
                to: CGPoint(
                    x: nextRect.minX,
                    y: nextRect.minY + radius
                ),
                curveType: .leftCircle
            )
            path.addCurve(
                from: CGPoint(
                    x: nextRect.minX,
                    y: nextRect.minY + radius
                ),
                to: CGPoint(
                    x: nextRect.minX,
                    y: nextRect.maxY - radius
                )
            )
        }
        
        return path
    }
    
    private func pathByAppendingRightStep(from currentRect: CGRect, to nextRect: CGRect, radius: CGFloat, path: UIBezierPath) -> UIBezierPath {
        let diff = currentRect.maxX - nextRect.maxX
        
        if diff == .zero {
            // по правому краю совпадают
            path.addCurve(
                from: CGPoint(
                    x: currentRect.maxX,
                    y: currentRect.minY + radius
                ),
                to: CGPoint(
                    x: currentRect.maxX,
                    y: currentRect.minY
                )
            )
            path.addCurve(
                from: CGPoint(
                    x: currentRect.maxX,
                    y: currentRect.minY
                ),
                to: CGPoint(
                    x: currentRect.maxX,
                    y: currentRect.minY
                )
            )
            path.addCurve(
                from: CGPoint(
                    x: currentRect.maxX,
                    y: currentRect.minY
                ),
                to: CGPoint(
                    x: nextRect.maxX,
                    y: nextRect.maxY - radius
                )
            )
            path.addCurve(
                from: CGPoint(
                    x: nextRect.maxX,
                    y: nextRect.maxY - radius
                ),
                to: CGPoint(
                    x: nextRect.maxX,
                    y: nextRect.minY + radius
                )
            )
        } else if diff < .zero {
            // следующий находится правее
            path.addCurve(
                from: CGPoint(
                    x: currentRect.maxX,
                    y: currentRect.minY + radius
                ),
                to: CGPoint(
                    x: currentRect.maxX + radius,
                    y: currentRect.minY
                ),
                curveType: .leftCircle
            )
            path.addCurve(
                from: CGPoint(
                    x: currentRect.maxX + radius,
                    y: currentRect.minY
                ),
                to: CGPoint(
                    x: nextRect.maxX - radius,
                    y: nextRect.maxY
                )
            )
            path.addCurve(
                from: CGPoint(
                    x: nextRect.maxX - radius,
                    y: nextRect.maxY
                ),
                to: CGPoint(
                    x: nextRect.maxX,
                    y: nextRect.maxY - radius
                ),
                curveType: .rightCircle
            )
            path.addCurve(
                from: CGPoint(
                    x: nextRect.maxX,
                    y: nextRect.maxY - radius
                ),
                to: CGPoint(
                    x: nextRect.maxX,
                    y: nextRect.minY + radius
                )
            )
        } else {
            // следующий находится левее
            path.addCurve(
                from: CGPoint(
                    x: currentRect.maxX,
                    y: currentRect.minY + radius
                ),
                to: CGPoint(
                    x: currentRect.maxX - radius,
                    y: currentRect.minY
                ),
                curveType: .rightCircle
            )
            path.addCurve(
                from: CGPoint(
                    x: currentRect.maxX - radius,
                    y: currentRect.minY
                ),
                to: CGPoint(
                    x: nextRect.maxX + radius,
                    y: nextRect.maxY
                )
            )
            path.addCurve(
                from: CGPoint(
                    x: nextRect.maxX + radius,
                    y: nextRect.maxY
                ),
                to: CGPoint(
                    x: nextRect.maxX,
                    y: nextRect.maxY - radius
                ),
                curveType: .leftCircle
            )
            path.addCurve(
                from: CGPoint(
                    x: nextRect.maxX,
                    y: nextRect.maxY - radius
                ),
                to: CGPoint(
                    x: nextRect.maxX,
                    y: nextRect.minY + radius
                )
            )
        }
        
        return path
    }
    
    private func realignLineFramgentRects(lineInfo: LabelTextView.LineInfo) -> [CGRect] {
        var rects = adjustRects(lineInfo.lines.map { $0.rect }, for: alignment).map { $0.expanded(by: inset) }
        rects.enumerated().forEach { index, _ in
            if index > rects.startIndex {
                adjustLineFragmentRect(at: index, in: &rects)
            }
        }
        
        return rects
    }
    
    private func adjustLineFragmentRect(
        at index: Int,
        in array: inout [CGRect]
    ) {
        guard index > 0 else { return }
        let previous = array[index - 1]
        let current = array[index]
        let maxDifference = 2 * current.height * radiusMultiplier
        
        let currentLeftEdgeIsCloseToPreviousFromRight = (current.origin.x - previous.origin.x < maxDifference && current.origin.x > previous.origin.x)
        let currentRightEdgeIsCloseToPreviousFromLeft = (previous.maxX - current.maxX < maxDifference && previous.maxX > current.maxX)
        let currentShouldBeExpanded = currentLeftEdgeIsCloseToPreviousFromRight || currentRightEdgeIsCloseToPreviousFromLeft
        
        let previousLeftEdgeIsCloseToCurrentFromRight = (previous.origin.x - current.origin.x < maxDifference && previous.origin.x > current.origin.x)
        let previousRightEdgeIsCloseToCurrentFromLeft = (current.maxX - previous.maxX < maxDifference && current.maxX > previous.maxX)
        let previousShouldBeExpanded = previousLeftEdgeIsCloseToCurrentFromRight || previousRightEdgeIsCloseToCurrentFromLeft
        
        if currentShouldBeExpanded {
            let newRect = CGRect(
                x: previous.origin.x,
                y: current.origin.y,
                width: previous.width,
                height: current.height
            )
            
            array[index] = newRect
        }
        
        if previousShouldBeExpanded {
            let newRect = CGRect(
                x: current.origin.x,
                y: previous.origin.y,
                width: current.width,
                height: previous.height
            )
            array[index - 1] = newRect
            
            adjustLineFragmentRect(at: index - 1, in: &array)
        }
    }
    
    private func adjustRects(_ rects: [CGRect], for alignment: TextAlignment?) -> [CGRect] {
        guard let alignment = alignment else { return rects }
        switch alignment {
        case .right:
            return rects.enumerated().map { index, rect in
                guard index > rects.startIndex else { return rect }
                return CGRect(
                    x: rect.origin.x + rects[0].maxX - rect.maxX,
                    y: rect.origin.y,
                    width: rect.width,
                    height: rect.height
                )
            }
        default:
            return rects
        }
    }
}

private extension UIBezierPath {
    enum CurveType {
        case linear
        case leftCircle
        case rightCircle
    }
    func addCurve(
        from startPoint: CGPoint,
        to endPoint: CGPoint,
        curveType: CurveType = .linear
    ) {
        let controlPoint1: CGPoint
        let controlPoint2: CGPoint
        
        switch curveType {
        case .linear:
            controlPoint1 = startPoint
            controlPoint2 = endPoint
        case .leftCircle:
            let radius = abs(startPoint.x - endPoint.x)
            let k: CGFloat = (4 / 3) * (sqrt(2) - 1)
            let sign: CGFloat = startPoint.y > endPoint.y ? -1 : 1
            
            if startPoint.x < endPoint.x {
                controlPoint1 = CGPoint(
                    x: startPoint.x,
                    y: startPoint.y + sign * k * radius
                )
                controlPoint2 = CGPoint(
                    x: endPoint.x - k * radius,
                    y: endPoint.y
                )
            } else {
                controlPoint1 = CGPoint(
                    x: startPoint.x - k * radius,
                    y: startPoint.y
                )
                controlPoint2 = CGPoint(
                    x: endPoint.x,
                    y: endPoint.y - sign * k * radius
                )
            }
        case .rightCircle:
            let radius = abs(startPoint.x - endPoint.x)
            let k: CGFloat = (4 / 3) * (sqrt(2) - 1)
            let sign: CGFloat = startPoint.y > endPoint.y ? -1 : 1
            
            if startPoint.x < endPoint.x {
                controlPoint1 = CGPoint(
                    x: startPoint.x + k * radius,
                    y: startPoint.y
                )
                controlPoint2 = CGPoint(
                    x: endPoint.x,
                    y: endPoint.y - sign * k * radius
                )
            } else {
                controlPoint1 = CGPoint(
                    x: startPoint.x,
                    y: startPoint.y + sign * k * radius
                )
                controlPoint2 = CGPoint(
                    x: endPoint.x + k * radius,
                    y: endPoint.y
                )
            }
        }
        
        addCurve(
            to: endPoint,
            controlPoint1: controlPoint1,
            controlPoint2: controlPoint2
        )
    }
}

private extension CGRect {
    func expanded(by inset: CGFloat) -> CGRect {
        return CGRect(
            x: origin.x - inset / 2,
            y: origin.y,
            width: width + inset,
            height: height
        )
    }
}
