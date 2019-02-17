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

enum MeteoCompassViewError: Error, CustomStringConvertible {
    case unknownView
    case windSensorError
    
    var description: String {
        switch self {
        case .unknownView: return "Unknown view detected"
        case .windSensorError: return "Unable to find wind sensor"
        }
    }
}

class MeteoCompassView: SKView {
    // MARK: - Class properties
    var midPoint = CGPoint(x: 0.0, y: 0.0)
    let k2PI: Double = 2.0 * Double.pi
    let kSize: CGFloat = 14
    var radiusCompass: CGFloat = 0.0
    var intervalTwelve: Double =  0.0
    var intervalThreeSixty = 0.0
    var intervalSixty = 0.0
    var angle: Double = 0.0
    var tickOffset = 0.0
    var prevDirection = 0.0

    // MARK: - Compass
    var compassNeedle: SKShapeNode?
    var compassFace: SKShapeNode?
    var centerNode: SKShapeNode?
    var theKitScene: SKScene?
    
    // MARK: - Sensor Pairs
    var upperRight: MeteoSensorNodePair?    // Upper Right Sensor Grouping <major, minor>
    var lowerRight: MeteoSensorNodePair?    // Lower Right Sensor Grouping <major, minor>
    var lowerLeft: MeteoSensorNodePair?     // Lower Left Sensor Grouping <major, minor>
    var upperLeft: MeteoSensorNodePair?     // Upper Left Sensor Grouping <major, minor>

    // MARK: - Overrides
    override convenience init(frame frameRect: NSRect) {
        self.init(frame: frameRect)
    }
    
    /// Make sure we save the user's preferences for the compass
    open func updatePreferences() {
        log.info("ToDo: Compass Prferences Saved ...")
/*
        theDelegate?.theDefaults?.compassCardinalMinorTickColor =
        theDelegate?.theDefaults?.compassCardinalMajorTickColor =
        theDelegate?.theDefaults?.compassCrosshairColor =
        theDelegate?.theDefaults?.compassRingColor =
        theDelegate?.theDefaults?.compassFrameColor =
        theDelegate?.theDefaults?.compassFaceColor =
        theDelegate?.theDefaults?.compassCaratColor =
        theDelegate?.theDefaults?.compassShowSensorBox =
*/
        theDelegate?.theDefaults?.compassULSensor = (upperLeft?.sensorID)!
        theDelegate?.theDefaults?.compassURSensor = (upperRight?.sensorID)!
        theDelegate?.theDefaults?.compassLLSensor = (lowerLeft?.sensorID)!
        theDelegate?.theDefaults?.compassLRSensor = (lowerRight?.sensorID)!
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
        
        /// Setup a call-forward listener for anyone to ask the Menu to update with a new observation
        NotificationCenter.default.addObserver(self, selector: #selector(observationRecieved(_:)), name: NSNotification.Name(rawValue: "NewObservationReceived"), object: nil)
    }
    
    @objc private func observationRecieved(_ theNotification: Notification) {
        upperLeft?.update()
        upperRight?.update()
        lowerLeft?.update()
        lowerRight?.update()
        
        guard let sensor = theDelegate?.theBridge?.findSensor(sensorName: "wind0dir") else {
            log.warning(MeteoCompassViewError.windSensorError)
            return
        }
        
        guard let value = sensor.measurement.value else {
            log.warning(MeteoCompassViewError.windSensorError)
            return
        }
        windDirection(direction: Double(value)!)
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

        if start-end == 0.0 {
            return  // No need to do anything ...
        }

/*        if direction == 0 && prevDirection == 0 {
            compassNeedle!.xScale = 0
            myNewPath.addArc(center: CGPoint(x: 0, y: 0), radius: radiusCompass + 15, startAngle: start,
                             endAngle: end, clockwise: true, transform: myTranslation)
        } else */
        if direction - prevDirection  <= -10.0 { // [36] Just reverse it if it's between +- 30° // compassNeedle.xScale = -1
            compassNeedle!.xScale = -1
            myNewPath.addArc(center: CGPoint(x: 0, y: 0), radius: radiusCompass + 15, startAngle: start,
                             endAngle: end, clockwise: false, transform: myTranslation)
//            print("\(self)[Reverse] --> Current:\(direction); Previous:\(prevDirection) --> Delta:\(direction-prevDirection)")
        } else {
            compassNeedle!.xScale = 1
            myNewPath.addArc(center: CGPoint(x: 0, y: 0), radius: radiusCompass + 15, startAngle: start,
                             endAngle: end, clockwise: true, transform: myTranslation)
//            print("\(self)[Forward] --> Current:\(direction); Previous:\(prevDirection) --> Delta:\(direction-prevDirection)")
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
        // Vertical Crosshair Line
        let verticalPath: CGMutablePath = CGMutablePath()
        verticalPath.move(to: CGPoint(x: frame.size.width / 2.0, y: (radiusCompass/2.0) + 45))
        verticalPath.addLine(to: CGPoint(x: frame.size.width / 2.0, y: frame.size.height - (radiusCompass/2) - 45))
        verticalPath.closeSubpath()
        let verticalLine = SKShapeNode(path: verticalPath)
        verticalLine.path = verticalPath
        verticalLine.strokeColor = (theDelegate?.theDefaults?.compassCrosshairColor)! // SKColor.white
        theKitScene!.addChild(verticalLine)
        
        // Horizontlal crosshair Line
        let horizontalPath: CGMutablePath = CGMutablePath()
        horizontalPath.move(to: CGPoint(x: (radiusCompass / 2.0) + 45, y: frame.size.height / 2.0))
        horizontalPath.addLine(to: CGPoint(x: frame.size.height - (radiusCompass/2) - 45, y: frame.size.height / 2.0))
        horizontalPath.closeSubpath()
        let horizontalLine = SKShapeNode(path: horizontalPath)
        horizontalLine.path = horizontalPath
        horizontalLine.strokeColor = (theDelegate?.theDefaults?.compassCrosshairColor)!
        theKitScene!.addChild(horizontalLine)
        
        // Upper Left
        let ULMajor: SKShapeNode = boxGenerator(size: CGSize(width: radiusCompass * 0.468, height: radiusCompass * 0.343),
                                                        point: CGPoint(x: midPoint.x - radiusCompass * 0.3, y: midPoint.y + radiusCompass * 0.406),
                                                        scene: theKitScene!)
//        let ULMajorLabel: SKLabelNode = SKLabelNode(text: "") // UL Major
        let ULMajorLabel: QJSKMultiLineLabel = QJSKMultiLineLabel(text: "", labelWidth: Double(ULMajor.frame.width-5.0), pos: CGPoint(x: 0, y: 0))
//        ULMajorLabel.verticalAlignmentMode = .center
//        ULMajorLabel.horizontalAlignmentMode = .center
        ULMajorLabel.fontSize = 16
        ULMajor.addChild(ULMajorLabel)
        ULMajor.fillColor = (theDelegate?.theDefaults?.compassFaceColor)! // SKColor.black
        ULMajor.strokeColor = border ? (theDelegate?.theDefaults?.compassSensorColor)! : SKColor.clear
        
        let ULMinor: SKShapeNode = boxGenerator(size: CGSize(width: radiusCompass * 0.468, height: radiusCompass * 0.125),
                                                        point: CGPoint(x: midPoint.x - radiusCompass * 0.3, y: midPoint.y + radiusCompass * 0.156),
                                                        scene: theKitScene!)
        let ULMinorLabel: SKLabelNode = SKLabelNode(text: "") // UL Minor
        ULMinorLabel.verticalAlignmentMode = .center
        ULMinorLabel.horizontalAlignmentMode = .center
        ULMinorLabel.fontSize = 12
        ULMinor.addChild(ULMinorLabel)
        ULMinor.fillColor = (theDelegate?.theDefaults?.compassFaceColor)! // SKColor.black
        ULMinor.strokeColor = border ? (theDelegate?.theDefaults?.compassSensorColor)! : SKColor.clear
        
        /// Bettery
        let ULBattery: SKSpriteNode = SKSpriteNode(imageNamed: "full-battery-color")
        ULBattery.size = CGSize(width: 18.0, height: 18.0)
        ULBattery.position = CGPoint(x: ULMajor.frame.width - 50.0, y: (ULMajor.frame.height / 2.0) - 8.0)
        ULBattery.isHidden = true
        ULMajor.addChild(ULBattery)
        
        // Sensor Icon
        let ULIcon: SKSpriteNode = SKSpriteNode()
        ULIcon.size = CGSize(width: 16.0, height: 16.0)
        ULIcon.isHidden = false // true
        let ULNode = SKEffectNode()
        ULNode.position = CGPoint(x: ULMajor.frame.width - 100, y: (ULMajor.frame.height / 2.0) - 8.0)
        ULNode.addChild(ULIcon)
        ULMajor.addChild(ULNode)

        upperLeft = MeteoSensorNodePair(major: ULMajor, minor: ULMinor, battery: ULBattery, icon: ULNode, sensorID: theDelegate?.theDefaults?.compassULSensor)
        if theDelegate?.theBridge != nil { upperLeft?.update() }
        
        // Upper Right
        let URMajor: SKShapeNode = boxGenerator(size: CGSize(width: radiusCompass * 0.468, height: radiusCompass * 0.343),
                                                       point: CGPoint(x: midPoint.x + radiusCompass * 0.3, y: midPoint.y + radiusCompass * 0.406),
                                                       scene: theKitScene!)
//        let URMajorLabel: SKLabelNode = SKLabelNode(text: "") // UR Major
        let URMajorLabel: QJSKMultiLineLabel = QJSKMultiLineLabel(text: "", labelWidth: Double(URMajor.frame.width-5.0), pos: CGPoint(x: 0, y: 0))
//        URMajorLabel.verticalAlignmentMode = .center
//        URMajorLabel.horizontalAlignmentMode = .center
        URMajorLabel.fontSize = 16
        URMajor.addChild(URMajorLabel)
        URMajor.fillColor = (theDelegate?.theDefaults?.compassFaceColor)! // SKColor.black
        URMajor.strokeColor = border ? (theDelegate?.theDefaults?.compassSensorColor)! : SKColor.clear
        
        let URMinor: SKShapeNode = boxGenerator(size: CGSize(width: radiusCompass * 0.468, height: radiusCompass * 0.125),
                                                       point: CGPoint(x: midPoint.x + radiusCompass * 0.3, y: midPoint.y + radiusCompass * 0.156),
                                                       scene: theKitScene!)
        let URMinorLabel: SKLabelNode = SKLabelNode(text: "") // UR Minor
        URMinorLabel.verticalAlignmentMode = .center
        URMinorLabel.horizontalAlignmentMode = .center
        URMinorLabel.fontSize = 12
        URMinor.addChild(URMinorLabel)
        URMinor.fillColor = (theDelegate?.theDefaults?.compassFaceColor)! // SKColor.black
        URMinor.strokeColor = border ? (theDelegate?.theDefaults?.compassSensorColor)! : SKColor.clear
        
        /// Bettery
        let URBattery: SKSpriteNode = SKSpriteNode(imageNamed: "full-battery-color")
        URBattery.size = CGSize(width: 18.0, height: 18.0)
        URBattery.position = CGPoint(x: URMajor.frame.width - 50.0, y: (URMajor.frame.height / 2.0) - 8.0)
        URBattery.isHidden = true
        URMajor.addChild(URBattery)

        // Sensor Icon
        let URIcon: SKSpriteNode = SKSpriteNode()
        URIcon.size = CGSize(width: 16.0, height: 16.0)
        URIcon.isHidden = false // true
        let URNode = SKEffectNode()
        URNode.position = CGPoint(x: URMajor.frame.width - 100, y: (URMajor.frame.height / 2.0) - 8.0)
        URNode.addChild(URIcon)
        URMajor.addChild(URNode)
        
        upperRight = MeteoSensorNodePair(major: URMajor, minor: URMinor, battery: URBattery, icon: URNode, sensorID: theDelegate?.theDefaults?.compassURSensor)
        if theDelegate?.theBridge != nil { upperRight?.update() }

        // Lower Left
        let LLMajor: SKShapeNode = boxGenerator(size: CGSize(width: radiusCompass * 0.468, height: radiusCompass * 0.343),
                                                        point: CGPoint(x: midPoint.x - radiusCompass * 0.3, y: midPoint.y - radiusCompass * 0.265),
                                                        scene: theKitScene!)
//        let LLMajorLabel: SKLabelNode = SKLabelNode(text: "") // LL Major
        let LLMajorLabel: QJSKMultiLineLabel = QJSKMultiLineLabel(text: "", labelWidth: Double(LLMajor.frame.width-5.0), pos: CGPoint(x: 0, y: 0))
//        LLMajorLabel.verticalAlignmentMode = .center
//        LLMajorLabel.horizontalAlignmentMode = .center
        LLMajorLabel.fontSize = 16
        LLMajor.addChild(LLMajorLabel)
        LLMajor.fillColor = (theDelegate?.theDefaults?.compassFaceColor)! // SKColor.black
        LLMajor.strokeColor = border ? (theDelegate?.theDefaults?.compassSensorColor)! : SKColor.clear
        
        let LLMinor: SKShapeNode = boxGenerator(size: CGSize(width: radiusCompass * 0.468, height: radiusCompass * 0.125),
                                                        point: CGPoint(x: midPoint.x - radiusCompass * 0.3, y: midPoint.y - radiusCompass * 0.515),
                                                        scene: theKitScene!)
        let LLMinorLabel: SKLabelNode = SKLabelNode(text: "") // LL Minor
        LLMinorLabel.verticalAlignmentMode = .center
        LLMinorLabel.horizontalAlignmentMode = .center
        LLMinorLabel.fontSize = 12
        LLMinor.addChild(LLMinorLabel)
        LLMinor.fillColor = (theDelegate?.theDefaults?.compassFaceColor)! // SKColor.black
        LLMinor.strokeColor = border ? (theDelegate?.theDefaults?.compassSensorColor)! : SKColor.clear
        
        /// Battery Icon
        let LLBattery: SKSpriteNode = SKSpriteNode(imageNamed: "full-battery-color")
        LLBattery.size = CGSize(width: 18.0, height: 18.0)
        LLBattery.position = CGPoint(x: LLMajor.frame.width - 50.0, y: (LLMajor.frame.height / 2.0) - 8.0)
        LLBattery.isHidden = true
        LLMajor.addChild(LLBattery)
        
        // Sensor Icon
        let LLIcon: SKSpriteNode = SKSpriteNode()
        LLIcon.size = CGSize(width: 16.0, height: 16.0)
        LLIcon.isHidden = false // true
        let LLNode = SKEffectNode()
        LLNode.position = CGPoint(x: LLMajor.frame.width - 100, y: (LLMajor.frame.height / 2.0) - 8.0)
        LLNode.addChild(LLIcon)
        LLMajor.addChild(LLNode)

        lowerLeft = MeteoSensorNodePair(major: LLMajor, minor: LLMinor, battery: LLBattery, icon: LLNode, sensorID: theDelegate?.theDefaults?.compassLLSensor)
        if theDelegate?.theBridge != nil { lowerLeft?.update() }

        // Lower Right
        let LRMajor: SKShapeNode = boxGenerator(size: CGSize(width: radiusCompass * 0.468, height: radiusCompass * 0.343),
                                                       point: CGPoint(x: midPoint.x + radiusCompass * 0.3, y: midPoint.y - radiusCompass * 0.265),
                                                       scene: theKitScene!)
//        let LRtMajorLabel: SKLabelNode = SKLabelNode(text: "") // LR Major
        let LRtMajorLabel: QJSKMultiLineLabel = QJSKMultiLineLabel(text: "", labelWidth: Double(LRMajor.frame.width-5.0), pos: CGPoint(x: 0, y: 0))

//        LRtMajorLabel.verticalAlignmentMode = .center
//        LRtMajorLabel.horizontalAlignmentMode = .center
        LRtMajorLabel.fontSize = 16
        LRMajor.addChild(LRtMajorLabel)
        LRMajor.fillColor = (theDelegate?.theDefaults?.compassFaceColor)! // SKColor.black
        LRMajor.strokeColor = border ? (theDelegate?.theDefaults?.compassSensorColor)! : SKColor.clear
        
        let LRMinor: SKShapeNode = boxGenerator(size: CGSize(width: radiusCompass * 0.468, height: radiusCompass * 0.125),
                                                       point: CGPoint(x: midPoint.x + radiusCompass * 0.3, y: midPoint.y - radiusCompass * 0.515),
                                                       scene: theKitScene!)
        let LRMinorLabel: SKLabelNode = SKLabelNode(text: "") // LR Minor
        LRMinorLabel.verticalAlignmentMode = .center
        LRMinorLabel.horizontalAlignmentMode = .center
        LRMinorLabel.fontSize = 12
        LRMinor.addChild(LRMinorLabel)
        LRMinor.fillColor = (theDelegate?.theDefaults?.compassFaceColor)! // SKColor.black
        LRMinor.strokeColor = border ? (theDelegate?.theDefaults?.compassSensorColor)! : SKColor.clear
        
        let LRBattery: SKSpriteNode = SKSpriteNode(imageNamed: "full-battery-color")
        LRBattery.size = CGSize(width: 18.0, height: 18.0)
        LRBattery.position = CGPoint(x: LRMajor.frame.width - 50.0, y: (LRMajor.frame.height / 2.0) - 8.0)
        LRBattery.isHidden = true
        LRMajor.addChild(LRBattery)
        
        // Sensor Icon
        let LRIcon: SKSpriteNode = SKSpriteNode()
        LRIcon.size = CGSize(width: 16.0, height: 16.0)
        LRIcon.isHidden = false // true
        let LRNode = SKEffectNode()
        LRNode.position = CGPoint(x: LRMajor.frame.width - 100, y: (LRMajor.frame.height / 2.0) - 8.0)
        LRNode.addChild(LRIcon)
        LRMajor.addChild(LRNode)
        
        lowerRight = MeteoSensorNodePair(major: LRMajor, minor: LRMinor, battery: LRBattery, icon: LRNode, sensorID: theDelegate?.theDefaults?.compassLRSensor)
        if theDelegate?.theBridge != nil { upperRight?.update() }
    }
}
