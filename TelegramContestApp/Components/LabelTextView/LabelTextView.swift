//
//  LabelTextView.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 13.10.2022.
//

import Foundation
import UIKit

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
    
    override var textContainerInset: UIEdgeInsets {
        didSet {
            updateLayoutManager()
        }
    }
    
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
    
    private var animatableTextAlignment: TextAlignment = .left
    
    private var fullRange: NSRange {
        return NSRange(location: .zero, length: attributedText.string.count)
    }
    
    init(frame: CGRect) {
        let layoutManager = LabelTextViewLayoutManager()
        let textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer()
        textContainer.heightTracksTextView = true
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)
        super.init(frame: frame, textContainer: textContainer)
        updateLayoutManager()
        delegate = self
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        delegate = self
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
    
    private func getLineInfo() -> LineInfo {
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
            guard index != lines.endIndex else { return line }
            let strippedRange = NSRange(location: line.range.location, length: line.range.length - 1)
            let lineSize = self.attributedText.attributedSubstring(from: strippedRange).boundingRect(
                with: CGSize(width: .greatestFiniteMagnitude, height: self.bounds.height),
                options: [.usesFontLeading, .usesLineFragmentOrigin],
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
    
    private func updateLayoutManager() {
        guard let layoutManager = layoutManager as? LabelTextViewLayoutManager else { return }
        layoutManager.textContainerOriginOffset = CGSize(width: textContainerInset.left, height: textContainerInset.top)
        layoutManager.invalidateDisplay(forCharacterRange: NSRange(location: 0, length: attributedText.length))
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
        let spacingValues: [AttributeInfo<CGFloat>] = lineInfo.lines.compactMap { line in
            guard let spacing = relativeSpacing(from: old, to: new, line: line, containerSize: lineInfo.containerSize) else { return nil }
            return AttributeInfo<CGFloat>(key: .customSpacing, value: spacing, range: line.range)
        }
        let currentSpacingAttributes: [AttributeInfo<CGFloat>] = getAttributes(for: .customSpacing, in: fullRange)
        let currentValues: [AttributeInfo<CGFloat>]
        if currentSpacingAttributes.isEmpty {
            currentValues = spacingValues.map { AttributeInfo<CGFloat>(key: .customSpacing, value: .zero, range: $0.range) }
        } else {
            // Если нашлись значения, то анимация сейчас уже в процессе, интерполировать нужно не от нуля, а от текущих значений
            currentValues = currentSpacingAttributes
        }
        let oldTintColor = tintColor
        tintColor = .clear
        animator.animateProgress(
            duration: Durations.third
        ) { [weak self] progress in
            guard let self = self else { return }
            let adjustedSpacingValues = spacingValues.enumerated().map { index, attr -> AttributeInfo<CGFloat> in
                let diff = attr.value - currentValues[index].value
                let resultSpacing = currentValues[index].value + diff * progress
                return AttributeInfo<CGFloat>(key: .customSpacing, value: resultSpacing, range: attr.range)
            }
            adjustedSpacingValues.forEach {
                self.addAttribute(attr: $0.value, for: $0.key, in: $0.range)
            }
        } completion: { [weak self] in
            guard let self = self else { return }
            let spacingAttributes: [AttributeInfo<CGFloat>] = self.getAttributes(for: .customSpacing, in: self.fullRange)
            self.removeAttributes(attrs: spacingAttributes)
            self.textAlignment = new.nsTextAlignment
            self.tintColor = oldTintColor
            self.updateCustomizationViewConfiguration()
            
        }
    }
    
    private func relativeSpacing(from old: TextAlignment, to new: TextAlignment, line: LineInfo.Line, containerSize: CGSize) -> CGFloat? {
        switch (old, new) {
        case (.left, .right):
            return containerSize.width - line.rect.width
        case (.left, .center):
            return (containerSize.width - line.rect.width) / 2
        case (.right, .left):
            return -(containerSize.width - line.rect.width)
        case (.right, .center):
            return -(containerSize.width - line.rect.width) / 2
        case (.center, .left):
            return -(containerSize.width - line.rect.width) / 2
        case (.center, .right):
            return (containerSize.width - line.rect.width) / 2
        default:
            return nil
        }
    }
}
