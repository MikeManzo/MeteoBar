//
//  MeteoCompassView.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/26/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import SpriteKit
import SceneKit
import Cocoa

class MeteoCompassView: SKView {
    // MARK: - Class properties
    var midPoint = CGPoint(x: 0.0, y: 0.0)
    let k2PI: Double = 2 * Double.pi
    let kSize: CGFloat = 14
    var radiusCompass: CGFloat = 0.0
    var intervalTwelve: Double =  0.0
    var intervalThreeSixty = 0.0
    var intervalSixty = 0.0
    var angle: Double = 0.0
    var tickOffset = 0.0
    var prevDirection = 0.0

    var compassNeedle: SKShapeNode?
    var compassFace: SKShapeNode?
    var centerNode: SKShapeNode?
    var theKitScene: SKScene?
    
    var testViews = [CollectionItemDropView]()

    // MARK: - Overrides
    override convenience init(frame frameRect: NSRect) {
        self.init(frame: frameRect)
    }
    
    /// Make sure we save the user's preferences for the compass
    func updatePreferences() {
        log.info("ToDo: Compass Prferences Saved ...")
/*
        (theDelegate?.theDefaults?.compassCardinalMinorTickColor)! =
        (theDelegate?.theDefaults?.compassCardinalMajorTickColor)! =
        (theDelegate?.theDefaults?.compassCrosshairColor)! =
        (theDelegate?.theDefaults?.compassRingColor)! =
        (theDelegate?.theDefaults?.compassFrameColor)! =
        (theDelegate?.theDefaults?.compassFaceColor)! =
        (theDelegate?.theDefaults?.compassCaratColor)! =
        (theDelegate?.theDefaults?.compassShowSensorBox)! = false
*/
    }
    
    ///
    /// [Example](https://stackoverflow.com/questions/33761985/how-to-create-a-overlayskscene-swift-xcode-to-display-a-hud-or-controls#)
    ///
    override func awakeFromNib() {
        // Center point of the frame
        midPoint = CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0)
        
        // Radius of the planned compassFace
        radiusCompass = (min(frame.height, frame.width)) * 0.4 //0.333

        // Create a scene, add something to it
        theKitScene = SKScene(size: frame.size)
        theKitScene!.backgroundColor = (theDelegate?.theDefaults?.compassFrameColor)! // NSColor.black

        // Determine radian spacing...
        tickOffset = (Double(radiusCompass) - Double(kSize * 1.75))
        intervalThreeSixty = k2PI / 360.0
        intervalTwelve =  k2PI / 16.0
        intervalSixty = k2PI / 60.0
        angle = Double.pi/2.0
        
        // Place a compassFace node in the center
        compassFace = nodeGenerator(size: CGFloat(radiusCompass), point: CGPoint(x: midPoint.x, y: midPoint.y), scene: theKitScene!)
        compassFace!.fillColor =  (theDelegate?.theDefaults?.compassFaceColor)! // SKColor.black
        compassFace!.strokeColor = (theDelegate?.theDefaults?.compassRingColor)! // SKColor.yellow
        
        // Place a normal node in the center
        centerNode = nodeGenerator(size: 3, point: CGPoint(x: midPoint.x, y: midPoint.y), scene: theKitScene!)
        centerNode!.fillColor = (theDelegate?.theDefaults?.compassCrosshairColor)! // SKColor.white
        
        // Create the carat for discreet wind direction
        compassNeedle = createRoundedTriangle(centerPoint: CGPoint(x: 0, y: 0), width: 24, height: 24, radius: 2, degrees: 90, scene: theKitScene)!
        compassNeedle!.zPosition = 10
      
        drawCardinalTicks(scene: theKitScene!)
        
        drawCardinalDirections(scene: theKitScene!)
        
        fourQuadsMajorMinor(border: (theDelegate?.theDefaults?.compassShowSensorBox)!)
                
        self.presentScene(theKitScene)
        
        /// TESTING
        var viewPoint = theKitScene!.convertPoint(toView: midPoint)
        viewPoint.x += 8
        viewPoint.y += 9
        
        var testView = CollectionItemDropView(identifier: "Upper Right", frameRect: NSRect(origin: viewPoint, size: CGSize(width: 80, height: 90)))
        testView.wantsLayer = true
        testView.delegate = self
        testViews.append(testView)

        viewPoint.x -= 97
        testView = CollectionItemDropView(identifier: "Upper Left", frameRect: NSRect(origin: viewPoint, size: CGSize(width: 80, height: 90)))
        testViews.append(testView)

        viewPoint.y -= 107
        testView = CollectionItemDropView(identifier: "Lower Left", frameRect: NSRect(origin: viewPoint, size: CGSize(width: 80, height: 90)))
        testViews.append(testView)

        viewPoint = theKitScene!.convertPoint(toView: midPoint)
        viewPoint.x += 8
        viewPoint.y -= 97
        testView = CollectionItemDropView(identifier: "Lower Right", frameRect: NSRect(origin: viewPoint, size: CGSize(width: 80, height: 90)))
        testViews.append(testView)
        
        for myView in testViews {
            addSubview(myView)
        }
        /// TESTING
      }
    
    // MARK: - Shapes

    /// Move the carat to face the direction the wind is blowing
    ///
    /// - Parameters:
    ///   - startDegrees: Degrees to start
    ///   - endDegrees: Degrees to end
    func windDirection(direction: Double) {
        let offset = (frame.width / 2.0)
        let myTranslation = CGAffineTransform(translationX: offset, y: offset)
        let start = CGFloat((90.0 - prevDirection) * Double.pi/180.0)
        let end = CGFloat((90.0 - direction) * Double.pi/180.0)
        
        let myNewPath = CGMutablePath()
        
        if direction == 0 && prevDirection == 0 {
            compassNeedle!.xScale = 0
            myNewPath.addArc(center: CGPoint(x: 0, y: 0), radius: radiusCompass + 15, startAngle: start,
                             endAngle: end, clockwise: true, transform: myTranslation)
        } else if direction - prevDirection  <= -36.0 { // Just reverse it if it's between +- 30° // compassNeedle.xScale = -1
            compassNeedle!.xScale = -1
            myNewPath.addArc(center: CGPoint(x: 0, y: 0), radius: radiusCompass + 15, startAngle: start,
                             endAngle: end, clockwise: false, transform: myTranslation)
        } else {
            compassNeedle!.xScale = 1
            myNewPath.addArc(center: CGPoint(x: 0, y: 0), radius: radiusCompass + 15, startAngle: start,
                             endAngle: end, clockwise: true, transform: myTranslation)
        }
        
        let pathNode = SKShapeNode(path: myNewPath)
        pathNode.strokeColor = SKColor.clear
        theKitScene!.addChild(pathNode)
        prevDirection = direction
        
        let myAction = SKAction.follow(pathNode.path!, asOffset: false, orientToPath: true, duration: 3)
        compassNeedle!.run(myAction)
    }
    
    /// Draws the major/minor cardinal ticks around the compass face
    ///
    /// - Parameter scene: the scene to add the ticks to
    ///
    private func drawCardinalTicks(scene: SKScene) {
        angle = Double.pi/2.0
        
        for index in 1...64 {  // 24 0...16
            angle -= k2PI / 64.0 // intervalTwelve
            
            let pathToDraw: CGMutablePath = CGMutablePath()
            let myLine: SKShapeNode?
            let radius: CGFloat = frame.width / 2.0 // 240.0 //r
            
            pathToDraw.move(to: CGPoint(x: midPoint.x + (radiusCompass - 1) * cos(CGFloat(angle)),
                                        y: midPoint.y + (radiusCompass - 1) * sin(CGFloat(angle)) ))
            
            if index % 4 == 0 {   // Major ticks (N, NW, W, SW, S, SE, E, NE) %2
                pathToDraw.addLine(to: CGPoint(x: radius + cos(CGFloat(angle)) * (frame.width*0.34), y: radius + sin(CGFloat(angle)) * (frame.width*0.34)))
                pathToDraw.closeSubpath()
                myLine = SKShapeNode(path: pathToDraw)
                myLine?.path = pathToDraw
                myLine?.strokeColor = (theDelegate?.theDefaults?.compassCardinalMajorTickColor)! //SKColor.blue
                myLine?.lineWidth = 4
            } else if index % 2 == 0 {   // Major ticks (N, NW, W, SW, S, SE, E, NE) %2
                pathToDraw.addLine(to: CGPoint(x: radius + cos(CGFloat(angle)) * (frame.width*0.36), y: radius + sin(CGFloat(angle)) * (frame.width*0.36)))
                pathToDraw.closeSubpath()
                myLine = SKShapeNode(path: pathToDraw)
                myLine?.path = pathToDraw
                myLine?.strokeColor = (theDelegate?.theDefaults?.compassCardinalMinorTickColor)! // SKColor.white
                myLine?.lineWidth = 2
            } else { // Minor ticks (NNW, WNW, WSW, SSW, SSE, ESE, ENE, NNE)
                pathToDraw.addLine(to: CGPoint(x: radius + cos(CGFloat(angle)) * (frame.width*0.38), y: radius + sin(CGFloat(angle)) * (frame.width*0.38)))
                pathToDraw.closeSubpath()
                myLine = SKShapeNode(path: pathToDraw)
                myLine?.path = pathToDraw
                myLine?.strokeColor = (theDelegate?.theDefaults?.compassCardinalMinorTickColor)! // SKColor.white
                myLine?.lineWidth = 1
            }

            scene.addChild(myLine!)
        }
    }
    
    /// Draws the major/minor cardinal directions around the compass face
    ///
    /// - Parameter scene: the scene to add the text to
    //
    private func drawCardinalDirections(scene: SKScene) {
        let cardinalDict: [Int: String] = [ 16: "N",   1: "NNE",  2: "NE",  3: "ENE", 4: "E",   5: "ESE",  6: "SE",  7: "SSE",
                                           8: "S",   9: "SSW", 10: "SW", 11: "WSW", 12: "W", 13: "WNW", 14: "NW", 15: "NNW" ]
        
        angle = Double.pi/2.0
        for index in 1...16 {
            angle -= intervalTwelve
            let node: SKShapeNode = nodeGenerator(size: kSize,
                                                 point: CGPoint( x: midPoint.x + (radiusCompass + 15) * CGFloat(cos(angle)),
                                                                 y: midPoint.y + (radiusCompass + 15) * CGFloat(sin(angle))),
                                                 scene: scene)

            let label: SKLabelNode = SKLabelNode(text: cardinalDict[index])
            node.addChild(label)
            node.fillColor = (theDelegate?.theDefaults?.compassFrameColor)! // SKColor.black
            node.strokeColor = SKColor.clear
            label.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
            label.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
            
            if index % 4 == 0 {
                label.fontName = "Menlo-Bold"
                label.fontSize = 20
            } else if index % 2 == 0 {
                label.fontName = "Menlo-Regular"
                label.fontSize = 16
            } else {
                label.fontName = "Menlo-Italic"
                label.fontSize = 12
            }
        }
    }
    
    /// Generate a Triangle
    ///
    /// [Example](https://stackoverflow.com/questions/20442203/uibezierpath-triangle-with-rounded-edges?noredirect=1&lq=1#)
    ///
    /// - Parameters:
    ///   - centerPoint: center of the triangle
    ///   - width: wiudth of triangle
    ///   - height: height of triangle
    ///   - radius: radius of the corners
    ///   - degrees: degree of the rounded corner
    ///   - scene: scene to add the triangle to
    /// - Returns: fully formed triangle
    ///
    private func createRoundedTriangle(centerPoint: CGPoint, width: CGFloat, height: CGFloat, radius: CGFloat, degrees: CGFloat, scene: SKScene? = nil) -> SKShapeNode? {
        let point1 = CGPoint(x: -width / 2, y: height / 2)
        let point2 = CGPoint(x: 0, y: -height / 2)
        let point3 = CGPoint(x: width / 2, y: height / 2)
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: height / 2))
        path.addArc(tangent1End: point1, tangent2End: point2, radius: radius)
        path.addArc(tangent1End: point2, tangent2End: point3, radius: radius)
        path.addArc(tangent1End: point3, tangent2End: point1, radius: radius)
        path.closeSubpath()
        
        var myTranslation = CGAffineTransform(rotationAngle: degrees * CGFloat((Double.pi/180)))
        let myNewPath = path.copy(using: &myTranslation)
        
        guard let triangle = SKShapeNode(path: myNewPath!, centered: true) as SKShapeNode? else {
            return nil
        }
        
        triangle.strokeColor    = SKColor.clear
        triangle.fillColor      = (theDelegate?.theDefaults?.compassCaratColor)! // SKColor.red
        triangle.position       = centerPoint
        triangle.alpha          = 0.50
        triangle.glowWidth      = 0.1
        
        if scene != nil {
            scene?.addChild(triangle)
        }
        
        return triangle
    }
    
    /// Generate a circle
    ///
    /// - Parameters:
    ///   - size: size of circle
    ///   - point: centerpoint of circle
    ///   - scene: scene to add circle to
    /// - Returns: fully formed "node" <-- Circle
    ///
    private func nodeGenerator(size: CGFloat, point: CGPoint, scene: SKScene) -> SKShapeNode {
        let circle = SKShapeNode(circleOfRadius: size )
        circle.glowWidth = 0.1
        circle.position = point
        scene.addChild(circle)
        
        return circle
    }
    
    /// Generates  box
    ///
    /// - Parameters:
    ///   - size: size of the box
    ///   - point: center point of box
    ///   - scene: scene to add box to
    /// - Returns: fully formed box
    ///
    private func boxGenerator(size: CGSize, point: CGPoint, scene: SKScene) -> SKShapeNode {
        let box = SKShapeNode(rectOf: size ) // Size of box
        box.glowWidth = 0.1
        box.position = point
        scene.addChild(box)
        return box
    }
    
    // MARK: - Weather Nodes
    
    /// Draw four quads with major and minor boxes
    ///
    /// - Parameter border: draw border around boxes
    ///
    private func fourQuadsMajorMinor(border: Bool = false) {
        // Crosshairs
        // Vertical Line
        let verticalPath: CGMutablePath = CGMutablePath()
        verticalPath.move(to: CGPoint(x: frame.size.width / 2.0, y: (radiusCompass/2.0) + 45))
        verticalPath.addLine(to: CGPoint(x: frame.size.width / 2.0, y: frame.size.height - (radiusCompass/2) - 45))
        verticalPath.closeSubpath()
        let verticalLine = SKShapeNode(path: verticalPath)
        verticalLine.path = verticalPath
        verticalLine.strokeColor = (theDelegate?.theDefaults?.compassCrosshairColor)! // SKColor.white
        theKitScene!.addChild(verticalLine)
        
        // Horizontlal Line
        let horizontalPath: CGMutablePath = CGMutablePath()
        horizontalPath.move(to: CGPoint(x: (radiusCompass / 2.0) + 45, y: frame.size.height / 2.0))
        horizontalPath.addLine(to: CGPoint(x: frame.size.height - (radiusCompass/2) - 45, y: frame.size.height / 2.0))
        horizontalPath.closeSubpath()
        let horizontalLine = SKShapeNode(path: horizontalPath)
        horizontalLine.path = horizontalPath
        horizontalLine.strokeColor = (theDelegate?.theDefaults?.compassCrosshairColor)!
        theKitScene!.addChild(horizontalLine)
        
        // Upper Left
        let upperRightMajor: SKShapeNode = boxGenerator(size: CGSize(width: radiusCompass * 0.468, height: radiusCompass * 0.343),
                                                        point: CGPoint(x: midPoint.x - radiusCompass * 0.3, y: midPoint.y + radiusCompass * 0.406),
                                                        scene: theKitScene!)
        let upperRightMajorLabel: SKLabelNode = SKLabelNode(text: "") // UL Major
        upperRightMajorLabel.verticalAlignmentMode = .center
        upperRightMajorLabel.horizontalAlignmentMode = .center
        upperRightMajorLabel.fontSize = 18
        upperRightMajor.addChild(upperRightMajorLabel)
        upperRightMajor.fillColor = (theDelegate?.theDefaults?.compassFaceColor)! // SKColor.black
        upperRightMajor.strokeColor = border ? (theDelegate?.theDefaults?.compassSensorColor)! : SKColor.clear
        
        let upperRightMinor: SKShapeNode = boxGenerator(size: CGSize(width: radiusCompass * 0.468, height: radiusCompass * 0.125),
                                                        point: CGPoint(x: midPoint.x - radiusCompass * 0.3, y: midPoint.y + radiusCompass * 0.156),
                                                        scene: theKitScene!)
        let upperRightMinorLabel: SKLabelNode = SKLabelNode(text: "") // UL Minor
        upperRightMinorLabel.verticalAlignmentMode = .center
        upperRightMinorLabel.horizontalAlignmentMode = .center
        upperRightMinorLabel.fontSize = 12
        upperRightMinor.addChild(upperRightMinorLabel)
        upperRightMinor.fillColor = (theDelegate?.theDefaults?.compassFaceColor)! // SKColor.black
        upperRightMinor.strokeColor = border ? (theDelegate?.theDefaults?.compassSensorColor)! : SKColor.clear
        
        // Upper Right
        let upperLeftMajor: SKShapeNode = boxGenerator(size: CGSize(width: radiusCompass * 0.468, height: radiusCompass * 0.343),
                                                       point: CGPoint(x: midPoint.x + radiusCompass * 0.3, y: midPoint.y + radiusCompass * 0.406),
                                                       scene: theKitScene!)
        let upperLeftMajorLabel: SKLabelNode = SKLabelNode(text: "") // UR Major
        upperLeftMajorLabel.verticalAlignmentMode = .center
        upperLeftMajorLabel.horizontalAlignmentMode = .center
        upperLeftMajorLabel.fontSize = 18
        upperLeftMajor.addChild(upperLeftMajorLabel)
        upperLeftMajor.fillColor = (theDelegate?.theDefaults?.compassFaceColor)! // SKColor.black
        upperLeftMajor.strokeColor = border ? (theDelegate?.theDefaults?.compassSensorColor)! : SKColor.clear
        
        let upperLeftMinor: SKShapeNode = boxGenerator(size: CGSize(width: radiusCompass * 0.468, height: radiusCompass * 0.125),
                                                       point: CGPoint(x: midPoint.x + radiusCompass * 0.3, y: midPoint.y + radiusCompass * 0.156),
                                                       scene: theKitScene!)
        let upperLeftMinorLabel: SKLabelNode = SKLabelNode(text: "") // UR Minor
        upperLeftMinorLabel.verticalAlignmentMode = .center
        upperLeftMinorLabel.horizontalAlignmentMode = .center
        upperLeftMinorLabel.fontSize = 12
        upperLeftMinor.addChild(upperLeftMinorLabel)
        upperLeftMinor.fillColor = (theDelegate?.theDefaults?.compassFaceColor)! // SKColor.black
        upperLeftMinor.strokeColor = border ? (theDelegate?.theDefaults?.compassSensorColor)! : SKColor.clear
        
        // Lower Left
        let lowerRightMajor: SKShapeNode = boxGenerator(size: CGSize(width: radiusCompass * 0.468, height: radiusCompass * 0.343),
                                                        point: CGPoint(x: midPoint.x - radiusCompass * 0.3, y: midPoint.y - radiusCompass * 0.265),
                                                        scene: theKitScene!)
        let lowerRightMajorLabel: SKLabelNode = SKLabelNode(text: "") // LL Major
        lowerRightMajorLabel.verticalAlignmentMode = .center
        lowerRightMajorLabel.horizontalAlignmentMode = .center
        lowerRightMajorLabel.fontSize = 18
        lowerRightMajor.addChild(lowerRightMajorLabel)
        lowerRightMajor.fillColor = (theDelegate?.theDefaults?.compassFaceColor)! // SKColor.black
        lowerRightMajor.strokeColor = border ? (theDelegate?.theDefaults?.compassSensorColor)! : SKColor.clear
        
        let lowerRightMinor: SKShapeNode = boxGenerator(size: CGSize(width: radiusCompass * 0.468, height: radiusCompass * 0.125),
                                                        point: CGPoint(x: midPoint.x - radiusCompass * 0.3, y: midPoint.y - radiusCompass * 0.515),
                                                        scene: theKitScene!)
        let lowerRightMinorLabel: SKLabelNode = SKLabelNode(text: "") // LL Minor
        lowerRightMinorLabel.verticalAlignmentMode = .center
        lowerRightMinorLabel.horizontalAlignmentMode = .center
        lowerRightMinorLabel.fontSize = 12
        lowerRightMinor.addChild(lowerRightMinorLabel)
        lowerRightMinor.fillColor = (theDelegate?.theDefaults?.compassFaceColor)! // SKColor.black
        lowerRightMinor.strokeColor = border ? (theDelegate?.theDefaults?.compassSensorColor)! : SKColor.clear
        
        // Lower Right
        let lowerLeftMajor: SKShapeNode = boxGenerator(size: CGSize(width: radiusCompass * 0.468, height: radiusCompass * 0.343),
                                                       point: CGPoint(x: midPoint.x + radiusCompass * 0.3, y: midPoint.y - radiusCompass * 0.265),
                                                       scene: theKitScene!)
        let lowerLeftMajorLabel: SKLabelNode = SKLabelNode(text: "") // LR Major
        lowerLeftMajorLabel.verticalAlignmentMode = .center
        lowerLeftMajorLabel.horizontalAlignmentMode = .center
        lowerLeftMajorLabel.fontSize = 18
        lowerLeftMajor.addChild(lowerLeftMajorLabel)
        lowerLeftMajor.fillColor = (theDelegate?.theDefaults?.compassFaceColor)! // SKColor.black
        lowerLeftMajor.strokeColor = border ? (theDelegate?.theDefaults?.compassSensorColor)! : SKColor.clear
        
        let lowerLeftMinor: SKShapeNode = boxGenerator(size: CGSize(width: radiusCompass * 0.468, height: radiusCompass * 0.125),
                                                       point: CGPoint(x: midPoint.x + radiusCompass * 0.3, y: midPoint.y - radiusCompass * 0.515),
                                                       scene: theKitScene!)
        let lowerLeftMinorLabel: SKLabelNode = SKLabelNode(text: "") // LR Minor
        lowerLeftMinorLabel.verticalAlignmentMode = .center
        lowerLeftMinorLabel.horizontalAlignmentMode = .center
        lowerLeftMinorLabel.fontSize = 12
        lowerLeftMinor.addChild(lowerLeftMinorLabel)
        lowerLeftMinor.fillColor = (theDelegate?.theDefaults?.compassFaceColor)! // SKColor.black
        lowerLeftMinor.strokeColor = border ? (theDelegate?.theDefaults?.compassSensorColor)! : SKColor.clear
    }
}

extension MeteoCompassView: CollectionItemDropViewDelegate {
    func dragDropView(_ dragDropView: CollectionItemDropView, droppedFileWithURL URL: URL) {
        log.info("Hello!")
    }
    
    func dragDropView(_ dragDropView: CollectionItemDropView, droppedFilesWithURLs URLs: [URL]) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Please drop only one file"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
