//
//  QJSKMultiLineNode.swift
//  MeteoBar
//
//  Original citation: [Multi line label in Sprite Kit in Swift](https://gist.github.com/klappy/8cd81068f066b6e36f44)
//  Adopted by Mike Manzo on 2/16/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Foundation
import SpriteKit

/// Multi line label in Sprite Kit
class QJSKMultiLineLabel: SKNode {
    // MARK: - Variables
    var labels: [SKLabelNode] = []
    var labelHeight: Double = 0.0
    var rect: SKShapeNode?
    var dontUpdate = false

    // MARK: - Properties
    /// A series of didSets so we can update the node if anything chanegs
    
    /// Width of the Label
    var labelWidth: Double {
        didSet {
            update()
            }
    }

    /// Display Text
    var text: String? {
        didSet {
            update()
            
        }
    }

    /// Name of font to use
    var fontName: String {
        didSet {
            update()
        }
    }
    
    /// Size of font to use
    var fontSize: CGFloat {
        didSet {
            update()
        }
    }
    
    /// Center Point of Node
    var pos: CGPoint {
        didSet {
            update()
        }
    }
    
    /// Color of Text
    var fontColor: SKColor {
        didSet {
            update()
        }
    }
    
    /// Spacing between lines
    var leading: Double {
        didSet {
            update()
        }
    }
    
    /// Alignment
    var alignment: SKLabelHorizontalAlignmentMode {
        didSet {
            update()
        }
    }
    
    /// Do we want to show the enclosing box?
    var shouldShowBorder: Bool = false {
        didSet {
            update()
        }
    }

    // MARK: - Implementation
    init(text: String, labelWidth: Double, pos: CGPoint, fontSize: CGFloat, fontColor: SKColor=SKColor.white,
         leading: Double = 10.0, alignment: SKLabelHorizontalAlignmentMode = .center, shouldShowBorder: Bool = false) {
        self.fontName           = ".AppleSystemUIFont"
        self.shouldShowBorder   = shouldShowBorder
        self.leading            = leading * 1.50
        self.labelWidth         = labelWidth
        self.fontColor          = fontColor
        self.alignment          = alignment
        self.fontSize           = fontSize
        self.text               = text
        self.pos                = pos
        
        super.init()
        self.update()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Update the Node due to a change
    /// ## Special Note ##
    ///   - If we want to change properties without updating the text field,
    ///     set 'dontUpdate' to false and call the update method manually.
    ///     otherwise, everytime a property changes, so does the Node
    ///
    func update() {
        if dontUpdate { return }

        if !labels.isEmpty {
            for label in labels {
                label.removeFromParent()
            }
            labels = []
        }
        
        let separators = CharacterSet.whitespacesAndNewlines
        let lineSeparators = NSCharacterSet.newlines
        let paragraphs = text!.components(separatedBy: lineSeparators)
        var lineCount = 0.0
        
        for paragraph in paragraphs {
            let words = paragraph.components(separatedBy: separators)
            var finalLine = false
            var wordCount = -1
            while !finalLine {
                lineCount += 1
                var lineLength = CGFloat(0)
                var lineString = ""
                var lineStringBeforeAddingWord = ""
                
                // Creation of the SKLabelNode itself
                let label = SKLabelNode(fontNamed: fontName)
                // Name each label node so we can animate it if we wish
                label.name = "line\(lineCount)"
                label.horizontalAlignmentMode = alignment
                label.fontSize = fontSize
                label.fontColor = fontColor
                
                while lineLength < CGFloat(labelWidth) {
                    wordCount += 1
                    if wordCount > words.count-1 {
                        finalLine = true
                        break
                    } else {
                        lineStringBeforeAddingWord = lineString
                        lineString = "\(lineString) \(words[wordCount])"
                        label.text = lineString
                        lineLength = label.frame.size.width
                    }
                }
                if lineLength > 0 {
                    wordCount -= 1
                    if !finalLine {
                        lineString = lineStringBeforeAddingWord
                    }
                    label.text = lineString
                    var linePos = pos
                    if alignment == .left {
                        linePos.x -= CGFloat(labelWidth / 2)
                    } else if alignment == .right {
                        linePos.x += CGFloat(labelWidth / 2)
                    }
                    linePos.y += CGFloat(-leading * lineCount)
                    // label.position = CGPointMake( linePos.x , linePos.y )
                    label.position = CGPoint(x: linePos.x , y: linePos.y )
                    self.addChild(label)
                    labels.append(label)
                }
            }
        }
        labelHeight = lineCount * leading
        showBorder()
    }
    
    /// Show/Create the border for this Node
    func showBorder() {
        if !shouldShowBorder { return }
        if let rect = self.rect {
            rect.path = nil // MRM: Memory Leak?
            self.removeChildren(in: [rect])
        }
        self.rect = SKShapeNode(rectOf: CGSize(width: labelWidth, height: labelHeight))
        if let rect = self.rect {
            rect.strokeColor = SKColor.white
            rect.lineWidth = 1
            rect.position = CGPoint(x: pos.x, y: pos.y - (CGFloat(labelHeight) / 2.0))
            self.addChild(rect)
        }
    }
}
