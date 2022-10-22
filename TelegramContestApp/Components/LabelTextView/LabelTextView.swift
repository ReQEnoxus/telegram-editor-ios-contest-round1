//
//  LabelTextView.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 13.10.2022.
//

import Foundation
import UIKit

protocol OutlineLabelDelegate: AnyObject {
    func didChangeOutlineMode(from outline: OutlineMode, to targetOutline: OutlineMode)
    func didChangeLineInfo(to new: LabelTextView.LineInfo, alignment: TextAlignment?, shouldAnimate: Bool)
}

extension OutlineLabelDelegate {
    func didChangeOutlineMode(from outline: OutlineMode, to targetOutline: OutlineMode) {}
    func didChangeLineInfo(to new: LabelTextView.LineInfo) {}
}

final class LabelTextView: UITextView {
    struct LineInfo {
        struct Line {
            let rect: CGRect
            let range: NSRange
        }
        let containerSize: CGSize
        let lines: [Line]
    }
    
    struct AttributeInfo<T> {
        let key: NSMutableAttributedString.Key
        let value: T
        let range: NSRange
    }
    
    weak var outlineDelegate: OutlineLabelDelegate?
    private var configuration: LabelTextViewConfiguration?
    private weak var customizationView: FontCustomizationAccessoryView?
    private var animator = Animator()
    
    private var currentAttributeRange: NSRange {
        if selectedRange.length == .zero {
            return fullRange
        } else {
            return selectedRange
        }
    }
    
    private var currentExclusionRects: [CGRect] = [] {
        didSet {
            textContainer.exclusionPaths = currentExclusionRects.map { UIBezierPath(rect: $0) }
        }
    }
    
    private var fullRange: NSRange {
        return NSRange(location: .zero, length: attributedText.string.count)
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        delegate = self
        backgroundColor = .clear
        isScrollEnabled = false
        textContainerInset = .zero
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        textContainer.lineFragmentPadding = .zero
        contentMode = .topLeft
        textDragInteraction?.isEnabled = false
        translatesAutoresizingMaskIntoConstraints = false
        keyboardAppearance = .dark
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.2
        
        typingAttributes = [
            .paragraphStyle: paragraph
        ]
        
    }
    
    private func updateCustomizationViewConfiguration() {
        guard let configuration = configuration else { return }

        customizationView?.configure(
            with: FontCustomizationAccessoryViewConfiguration(
                fontItems: configuration.supportedFonts.map { font in
                    FontCustomizationAccessoryViewConfiguration.FontItem(
                        font: font,
                        name: font.fontName,
                        isSelected: contains(font: font, in: currentAttributeRange, exclusively: true)
                    )
                },
                textAlignment: TextAlignment.from(nsTextAlignment: textAlignment)
            )
        )
    }
    
    private func contains(font: UIFont, in range: NSRange, exclusively: Bool) -> Bool {
        let fontsInRange: [UIFont] = getAttributes(for: .font, in: range).map { $0.value }
        let exclusiveCriteria = exclusively ? fontsInRange.count == 1 : true
        
        return fontsInRange.contains(font) && exclusiveCriteria
    }
    
    private func getAttributes<T>(for key: NSAttributedString.Key, in range: NSRange) -> [AttributeInfo<T>] {
        guard attributedText.string.contains(range: range) else { return [] }
        var attrs: [AttributeInfo<T>] = []
        attributedText.enumerateAttribute(key, in: range, options: []) { value, range, _ in
            guard let value = value as? T else { return }
            attrs.append(AttributeInfo<T>(key: key, value: value, range: range))
        }
        
        return attrs
    }
    
    private func addAttribute(attr: Any, for key: NSAttributedString.Key, in range: NSRange) {
        let mutableString = NSMutableAttributedString(attributedString: attributedText)
        mutableString.addAttribute(key, value: attr, range: range)
        attributedText = mutableString
    }
    
    private func removeAttributes<T>(attrs: [AttributeInfo<T>]) {
        let mutableString = NSMutableAttributedString(attributedString: attributedText)
        attrs.forEach {
            mutableString.removeAttribute($0.key, range: $0.range)
        }
        attributedText = mutableString
    }
    
    func getLineInfo() -> LineInfo {
        var size: CGSize = .zero
        var lines: [LineInfo.Line] = []
        
        layoutManager.enumerateLineFragments(forGlyphRange: fullRange) { _, rect, container, range, _ in
            size = container.size
            lines.append(
                LineInfo.Line(
                    rect: rect,
                    range: range
                )
            )
        }
        
        lines = lines.enumerated().map { index, line in
            let lineString = self.attributedText.attributedSubstring(from: line.range).withTrimmedWhitespaces
            let lineSize = lineString.boundingRect(
                with: CGSize(width: .greatestFiniteMagnitude, height: self.bounds.height),
                options: [.usesFontLeading],
                context: nil
            ).size
            return LineInfo.Line(
                rect: CGRect(
                    origin: line.rect.origin,
                    size: lineSize
                ),
                range: line.range
            )
        }
        
        return LineInfo(
            containerSize: size,
            lines: lines
        )
    }
}

extension LabelTextView: Configurable {
    
    func configure(with object: Any) {
        guard let configuration = object as? LabelTextViewConfiguration else { return }
        self.configuration = configuration
        if customizationView == nil {
            let view = FontCustomizationAccessoryView()
            inputAccessoryView = view
            customizationView = view
            view.delegate = self
        }
        updateCustomizationViewConfiguration()
    }
}

extension LabelTextView: UITextViewDelegate {
    func textViewDidChangeSelection(_ textView: UITextView) {
        updateCustomizationViewConfiguration()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.hasSuffix("\n") {
            textView.text = textView.text.trailingNewlinesTrimmed + "\n"
        }
        outlineDelegate?.didChangeLineInfo(to: getLineInfo(), alignment: TextAlignment.from(nsTextAlignment: textAlignment), shouldAnimate: false)
    }
}

private extension String {
    func contains(range: NSRange) -> Bool {
        return Range(range, in: self) != nil
    }
}

extension LabelTextView: FontCustomizationAccessoryViewDelegate {
    func didChangeFont(_ newFont: FontCustomizationAccessoryViewConfiguration.FontItem) {
        let lastSelectedRange = currentAttributeRange
        addAttribute(
            attr: newFont.font,
            for: .font,
            in: currentAttributeRange
        )
        if lastSelectedRange != fullRange {
            selectedRange = lastSelectedRange
        }
        updateCustomizationViewConfiguration()
    }
    
    func didChangeTextAlignment(from old: TextAlignment, to new: TextAlignment) {
        let lineInfo = getLineInfo()
        let oldTintColor = tintColor
        tintColor = .clear
        
        if currentExclusionRects.isEmpty {
            // Анимация еще не идет, начинаем
            currentExclusionRects = initialExclusionPaths(for: TextAlignment.from(nsTextAlignment: self.textAlignment), lineInfo: lineInfo)
            textAlignment = .left
        }
        
        let targetValues = initialExclusionPaths(for: new, lineInfo: lineInfo)
        
        if let outlineDelegate = outlineDelegate {
            let targetLineInfo = LineInfo(
                containerSize: lineInfo.containerSize,
                lines: lineInfo.lines.enumerated().map { index, line in
                    return LineInfo.Line(
                        rect: CGRect(
                            x: targetValues[index].width,
                            y: line.rect.origin.y,
                            width: line.rect.width,
                            height: line.rect.height
                        ),
                        range: line.range
                    )
                }
            )
            outlineDelegate.didChangeLineInfo(to: targetLineInfo, alignment: new, shouldAnimate: true)
        }
       
        let currentExclusionRectsCopy = currentExclusionRects
        animator.animateProgress(
            duration: Durations.half
        ) { [weak self] progress in
            guard let self = self else { return }
            let adjustedSpacingValues = targetValues.enumerated().map { index, targetValue -> CGRect in
                let diff = targetValue.width - currentExclusionRectsCopy[index].width
                let resultSpacing = currentExclusionRectsCopy[index].width + diff * progress
                return CGRect(
                    x: .zero,
                    y: targetValue.origin.y,
                    width: resultSpacing,
                    height: targetValue.height
                )
            }
            self.currentExclusionRects = adjustedSpacingValues
        } completion: { [weak self] in
            guard let self = self else { return }
            self.currentExclusionRects = []
            self.textAlignment = new.nsTextAlignment
            self.tintColor = oldTintColor
            self.updateCustomizationViewConfiguration()
        }
    }
    
    func didChangeOutlineMode(from outline: OutlineMode, to targetOutline: OutlineMode) {
        if case .text(let color) = targetOutline {
            let attrs: [NSAttributedString.Key: Any] = [
                .strokeColor: color,
                .strokeWidth: -5
            ]
            attrs.forEach {
                addAttribute(attr: $0.value, for: $0.key, in: fullRange)
            }
        } else {
            let mutableString = NSMutableAttributedString(attributedString: attributedText)
            mutableString.removeAttribute(.strokeColor, range: fullRange)
            mutableString.removeAttribute(.strokeWidth, range: fullRange)
            attributedText = mutableString
        }
        outlineDelegate?.didChangeOutlineMode(from: outline, to: targetOutline)
    }
    
    private func targetSpacing(for textAlignment: TextAlignment, line: LineInfo.Line, containerSize: CGSize) -> CGFloat {
        switch textAlignment {
        case .left:
            return .zero
        case .center:
            return (containerSize.width - line.rect.width) / 2
        case .right:
            return containerSize.width - line.rect.width
        }
    }
    
    private func initialExclusionPaths(for alignment: TextAlignment, lineInfo: LineInfo) -> [CGRect] {
        switch alignment {
        case .left:
            return lineInfo.lines.map { line in
                CGRect(
                    x: .zero,
                    y: line.rect.origin.y,
                    width: .zero,
                    height: line.rect.height
                )
            }
        case .right:
            return lineInfo.lines.map { line in
                CGRect(
                    x: .zero,
                    y: line.rect.origin.y,
                    width: targetSpacing(for: .right, line: line, containerSize: lineInfo.containerSize),
                    height: line.rect.height
                )
            }
        case .center:
            return lineInfo.lines.map { line in
                CGRect(
                    x: .zero,
                    y: line.rect.origin.y,
                    width: targetSpacing(for: .center, line: line, containerSize: lineInfo.containerSize),
                    height: line.rect.height
                )
            }
        }
    }
}
