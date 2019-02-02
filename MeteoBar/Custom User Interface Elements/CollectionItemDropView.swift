//
//  MeteoCompassView.swift
//  MeteoBar
//
//  [Inspired by](https://github.com/cupnoodle/ADragDropView)
//
//  Created by Mike Manzo on 1/26/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//
//

import Cocoa

///
///  Custom view for dropping a sensor from a collectiom view
///
///  # Notes #
///  - [Inspired By](https://github.com/cupnoodle/ADragDropView)
///  - [Custom Pastebord](http://swiftrien.blogspot.com/2015/06/using-drag-drop-from-swift.html)
///
///
public final class CollectionItemDropView: NSView {
    // Highlight the drop zone when mouse drag enters the drop view
    fileprivate var highlight: Bool = false
    
    // Check if the dropped file type is accepted
    fileprivate var fileTypeIsOk = false
    
    // Delegate so we can recieve system calls
    public weak var delegate: CollectionItemDropViewDelegate?
    
    // Identifier for window
    fileprivate var _uniqueIdentifier: String?
    
    /// Init for use from a Nib
    ///
    /// - Parameter coder: <#coder description#>
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        registerForDraggedTypes([NSPasteboard.PasteboardType(kUTTypeText as String)])
    }
    
    /// Init for use programatically
    ///
    /// - Parameter frameRect: <#frameRect description#>
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        registerForDraggedTypes([NSPasteboard.PasteboardType(kUTTypeText as String)])
    }
    
    /// Init for use programatically - with a unique identifier
    ///
    /// - Parameter frameRect: <#frameRect description#>
    public init(identifier: String, frameRect: NSRect) {
        super.init(frame: frameRect)
        
        registerForDraggedTypes([NSPasteboard.PasteboardType(kUTTypeText as String)])
        _uniqueIdentifier = identifier
    }
    
    /// Before an initial drop ... we want to give the user a visual so they know to "Drop Here"
    ///
    /// - Parameter dirtyRect: <#dirtyRect description#>
    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        NSColor.clear.set()
    
        __NSRectFillUsingOperation(dirtyRect, NSCompositingOperation.sourceOver)
        
        let outlineColor = NSColor.white
        outlineColor.set()
        outlineColor.setFill()
        
        let bounds = self.bounds
        let size = min(bounds.size.width - 8.0, bounds.size.height - 8.0)
        let width =  max(2.0, size / 32.0)
        let height = max(2.0, size / 32.0)
        let frame = NSRect(origin: CGPoint(x: (bounds.size.width-size)/2.0, y: (bounds.size.height-size)/2.0) , size: CGSize(width: size, height: size))
        
        NSBezierPath.defaultLineWidth = width
        
        // draw rounded corner square with dotted borders
        let squarePath = NSBezierPath(roundedRect: frame, xRadius: size/14.0, yRadius: size/14.0)
        let dash: [CGFloat] = [size / 10.0, size / 16.0]
        squarePath.setLineDash(dash, count: 2, phase: 2)
        squarePath.stroke()
        
        // draw arrow
        let arrowPath = NSBezierPath()
        let baseWidth = size / 12.0
        let baseHeight = size / 12.0
        let arrowWidth = baseWidth * 1.75
        let pointHeight = baseHeight * 3.0
        let offset = -size / 6.0
        let arrowColor = NSColor.gray

        arrowPath.move(to: CGPoint(x: bounds.size.width / 2.0 - baseWidth, y: bounds.size.height / 2.0 + baseHeight - offset+8))
        arrowPath.line(to: CGPoint(x: bounds.size.width / 2.0 + baseWidth, y: bounds.size.height / 2.0 + baseHeight - offset+8))
        arrowPath.line(to: CGPoint(x: bounds.size.width / 2.0 + baseWidth, y: bounds.size.height / 2.0 - baseHeight - offset+8))
        arrowPath.line(to: CGPoint(x: bounds.size.width / 2.0 + arrowWidth, y: bounds.size.height / 2.0 - baseHeight - offset+8))
        arrowPath.line(to: CGPoint(x: bounds.size.width / 2.0, y: bounds.size.height / 2.0 - pointHeight - offset+8))
        arrowPath.line(to: CGPoint(x: bounds.size.width / 2.0 - arrowWidth, y: bounds.size.height / 2.0 - baseHeight - offset+8))
        arrowPath.line(to: CGPoint(x: bounds.size.width / 2.0 - baseWidth, y: bounds.size.height / 2.0 - baseHeight - offset+8))
        arrowColor.set()
        arrowColor.setFill()
        arrowPath.fill()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: NSFont.systemFont(ofSize: 12.0),
            .foregroundColor: NSColor.white
        ]
        
        let myText = "Sensor Drop"
        let attributedString = NSAttributedString(string: myText, attributes: attributes)
        let stringRect = CGRect(x: 8.0 , y: height - 37, width: bounds.size.width - 16.0, height: bounds.size.height - 8.0)
        attributedString.draw(in: stringRect)
    }

    // MARK: - NSDraggingDestination
    public override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        highlight = true
        fileTypeIsOk = isExtensionAcceptable(draggingInfo: sender)
        
        self.setNeedsDisplay(self.bounds)
        return []
    }
    
    public override func draggingExited(_ sender: NSDraggingInfo?) {
        highlight = false
        self.setNeedsDisplay(self.bounds)
    }
    
    public override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return fileTypeIsOk ? .copy : []
    }
    
    public override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        // finished with dragging so remove any highlighting
        highlight = false
        self.setNeedsDisplay(self.bounds)
        
        return true
    }
    
    public override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let sensorID = sender.draggingPasteboard.pasteboardItems?.first?.string(forType: .string) else {
            return false
        }
        
        delegate?.dragDropView(self, uuID: _uniqueIdentifier!, dropValue: sensorID)

        return true
    }
    
    fileprivate func isExtensionAcceptable(draggingInfo: NSDraggingInfo) -> Bool {
        guard (draggingInfo.draggingPasteboard.pasteboardItems?.first?.string(forType: .string)) != nil else {
            return false
        }

        return true
    }
    
    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}

public protocol CollectionItemDropViewDelegate: class {
    func dragDropView(_ dragDropView: CollectionItemDropView, uuID: String, dropValue: String)
}
