//
//  LabelTextView.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 13.10.2022.
//

import Foundation
import UIKit

protocol OutlineLabelDelegate: AnyObject {
    func didChangeOutlineMode(from outline: OutlineMode, to targetOutline: OutlineMode, shouldAnimate: Bool)
    func didChangeLineInfo(to new: LabelTextView.LineInfo, alignment: TextAlignment?, shouldAnimate: Bool)
}

protocol AccessoryViewOperatingDelegate: AnyObject {
    func updateAccessory(selectedFont: UIFont, selectedAlignment: NSTextAlignment)
}

extension OutlineLabelDelegate {
    func didChangeOutlineMode(from outline: OutlineMode, to targetOutline: OutlineMode, shouldAnimate: Bool) {}
    func didChangeLineInfo(to new: LabelTextView.LineInfo) {}
}

final class LabelTextView: UITextView {
    private enum Constants {
        static let lineHeightMultiple: CGFloat = 1.2
    }
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
    
    var fontScale: Float = 1 {
        didSet {
            updateFontScale()
        }
    }

    weak var outlineDelegate: OutlineLabelDelegate?
    private var configuration: LabelTextViewConfiguration?
    weak var accessoryDelegate: AccessoryViewOperatingDelegate?
    private var animator = Animator()
    private var currentTextOutlineAttribute: AttributeInfo<UIColor>?
    private var currentFontSize: CGFloat = .zero
    
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
        let layoutManager = CustomOutlineLayoutManager()
        let textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer()
        textContainer.heightTracksTextView = true
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)
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
        textContainerInset = UIEdgeInsets(top: .zero, left: 4, bottom: .zero, right: 4)
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        textContainer.lineFragmentPadding = .zero
        contentMode = .topLeft
        textDragInteraction?.isEnabled = false
        translatesAutoresizingMaskIntoConstraints = false
        keyboardAppearance = .dark
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = Constants.lineHeightMultiple
        
        typingAttributes = [
            .paragraphStyle: paragraph
        ]
        
    }
    
    private func updateCustomizationViewConfiguration() {
        guard let selectedFont = typingAttributes[.font] as? UIFont else { return }
        accessoryDelegate?.updateAccessory(selectedFont: selectedFont, selectedAlignment: textAlignment)
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
    
    private func addAttribute<T>(attr: AttributeInfo<T>, range: NSRange? = nil) {
        preservingSelection {
            addAttribute(attr: attr.value, for: attr.key, in: range ?? attr.range)
        }
    }
    
    private func addAttribute(attr: Any, for key: NSAttributedString.Key, in range: NSRange) {
        preservingSelection {
            let mutableString = NSMutableAttributedString(attributedString: attributedText)
            mutableString.addAttribute(key, value: attr, range: range)
            attributedText = mutableString
        }
    }
    
    private func removeAttributes<T>(attrs: [AttributeInfo<T>]) {
        let mutableString = NSMutableAttributedString(attributedString: attributedText)
        attrs.forEach {
            mutableString.removeAttribute($0.key, range: $0.range)
        }
        attributedText = mutableString
    }
    
    private func updateFontScale() {
        guard let currentFont = font else { return }
        let scaledFont = currentFont.withSize(currentFontSize * CGFloat(fontScale))
        font = scaledFont
        typingAttributes[.font] = nil
        typingAttributes[.font] = scaledFont
    }
    
    func setFont(_ font: UIFont) {
        self.font = font
        currentFontSize = font.pointSize
        updateFontScale()
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
            let resultLineSize: CGSize
            let lineSize = lineString.boundingRect(
                with: CGSize(width: .greatestFiniteMagnitude, height: self.bounds.height),
                options: [.usesFontLeading],
                context: nil
            ).size
            if lineString.string.isBlank {
                let symbolHeight = Constants.lineHeightMultiple * (font?.lineHeight ?? .zero)
                resultLineSize = CGSize(width: symbolHeight, height: symbolHeight)
            } else {
                resultLineSize = lineSize
            }
            
            return LineInfo.Line(
                rect: CGRect(
                    origin: line.rect.origin,
                    size: resultLineSize
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
        textColor = configuration.initialTextColor
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
        if let currentOutline = currentTextOutlineAttribute {
            addAttribute(attr: currentOutline, range: fullRange)
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
    func didChangeGlobalColor(to color: UIColor, usingCustomOutline: Bool) {
        if usingCustomOutline {
            if color.isLight() == true {
                textColor = .black
            } else {
                textColor = .white
            }
        } else {
            textColor = color
        }
    }
    
    func didChangeFont(_ newFont: FontCustomizationAccessoryViewConfiguration.FontItem) {
        setFont(newFont.font)
        outlineDelegate?.didChangeLineInfo(to: getLineInfo(), alignment: TextAlignment.from(nsTextAlignment: textAlignment), shouldAnimate: false)
        updateCustomizationViewConfiguration()
    }
    
    func didChangeTextAlignment(from old: TextAlignment, to new: TextAlignment) {
        let lineInfo = getLineInfo()
        if lineInfo.lines.count == 1 {
            // Нет нужды анимировать, просто меняем textAlignment
            textAlignment = new.nsTextAlignment
            return
        }
        
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
    
    func didChangeOutlineMode(from outline: OutlineMode, to targetOutline: OutlineMode, shouldAnimate: Bool) {
        if case .text = targetOutline {
            handleTextOutlineChange(to: targetOutline, animated: shouldAnimate)
        } else if case .text = outline {
            handleTextOutlineChange(to: targetOutline, animated: shouldAnimate)
        }
        
        outlineDelegate?.didChangeOutlineMode(from: outline, to: targetOutline, shouldAnimate: shouldAnimate)
    }
    
    private func handleTextOutlineChange(to newMode: OutlineMode, animated: Bool) {
        if case .text(let color) = newMode {
            let attribute = AttributeInfo<UIColor>(key: .customOutline, value: color, range: fullRange)
            if animated {
                UIView.transition(with: self, duration: Durations.half, options: [.transitionCrossDissolve]) {
                    self.addAttribute(attr: attribute)
                } completion: { _ in }
            } else {
                self.addAttribute(attr: attribute)
            }
            currentTextOutlineAttribute = attribute
        } else {
            let remove: () -> Void = {
                self.preservingSelection {
                    let mutableString = NSMutableAttributedString(attributedString: self.attributedText)
                    mutableString.removeAttribute(.customOutline, range: self.fullRange)
                    self.attributedText = mutableString
                }
            }
            if animated {
                UIView.transition(with: self, duration: Durations.half, options: [.transitionCrossDissolve]) {
                    remove()
                } completion: { _ in }
            } else {
                remove()
            }
            currentTextOutlineAttribute = nil
        }
    }
    
    private func targetSpacing(for textAlignment: TextAlignment, line: LineInfo.Line, containerSize: CGSize) -> CGFloat {
        switch textAlignment {
        case .left:
            return .zero
        case .center:
            return (containerSize.width - line.rect.width).half
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
    
    private func preservingSelection(perform action: () -> Void) {
        let currentSelection = selectedRange
        action()
        selectedRange = currentSelection
    }
}
