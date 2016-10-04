//
//  CRNetworkButton.swift
//  CRNetworkButton
//
//  Created by Dmitry Pashinskiy on 5/17/16.
//  Copyright © 2016 Cleveroad Inc. All rights reserved.
//

import UIKit


public enum CRState {
    case Ready
    case Loading
    case Finishing
    case Finished
}


private struct Constants {
    
    static let contextID   = "kAnimationIdentifier"
    static let layerAnimation = "kLayerAnimation"
    
    static let prepareLoadingAnimDuration: NSTimeInterval = 0.2
    static let resetLinesPositionAnimDuration: NSTimeInterval = 0.2
    static let finishLoadingAnimDuration: NSTimeInterval  = 0.3
    static let checkMarkDelay: NSTimeInterval  = 0.3
    static let bounceDuration: NSTimeInterval  = 0.3
}

private struct AnimKeys {
    static let bounds = "bounds"
}

enum AnimContext: String {
    case LoadingStart
    case Loading
    case LoadingFinishing
}



@IBDesignable
public class CRNetworkButton: UIButton {
    
    // MARK: - Public variables
    
    /// measure in radians
    @IBInspectable public var dotLength: CGFloat = 0.1
    /// time for pass one lap
    @IBInspectable public var velocity: Double = 1
    /// lines count on loading state
    @IBInspectable public var linesCount: UInt = 2
    /// if set true, on tap will be called animation automatically
    @IBInspectable public var animateOnTap: Bool = true
    /// color of dots and line in loading state
    @IBInspectable public var crDotColor: UIColor = UIColor.greenColor()
    /// line width of the border
    @IBInspectable public var crLineWidth: CGFloat = 5
    /// after stop animate will set to default state
    @IBInspectable public var shouldAutoReverse: Bool = false
    /// allow to show progress, use **updateProgress** to manage button progress
    @IBInspectable public var progressMode: Bool = false
    /// border Color
    @IBInspectable public var crBorderColor: UIColor = UIColor.lightGrayColor() {
        didSet {
            borderLayer.borderColor = crBorderColor.CGColor
        }
    }
    @IBInspectable public var startText:String = "Go" {
        didSet {
            updateText()
        }
    }
    @IBInspectable public var endText:String = "Done" {
        didSet {
            updateText()
        }
    }
    
    /// will clear after calling
    public var completionHandler: (()->())?
    
    public var currState: CRState {
        return crState
    }
    
    
    // MARK: - Private Vars
    private lazy var borderLayer: CALayer = {
        let layer =  CALayer()
        layer.borderWidth = 0
        layer.borderColor = self.crBorderColor.CGColor
        layer.backgroundColor = nil
        return layer
    }()
    
    private lazy var progressLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = nil
        layer.strokeColor = self.crDotColor.CGColor
        layer.bounds = self.circleBounds
        layer.path = UIBezierPath(arcCenter: self.boundsCenter, radius: self.boundsCenter.y - self.crLineWidth / 2,
                                  startAngle: CGFloat(-M_PI_2), endAngle: 3*CGFloat(M_PI_2), clockwise: true).CGPath
        
        layer.strokeEnd = 0
        layer.lineCap = kCALineCapRound
        layer.lineWidth = self.crLineWidth
        
        return layer
    }()
    
    private lazy var checkMarkLayer: CAShapeLayer = {
        return self.createCheckMark()
    }()
    
    private var crState: CRState = .Ready {
        didSet {
            handleCRState( crState )
        }
    }
    
    private var circleBounds: CGRect {
        var newRect = startBounds
        newRect.size.width = startBounds.height
        return newRect
    }
    
    private var boundsCenter: CGPoint {
        return CGPoint(x: circleBounds.midX, y: circleBounds.midY)
    }
    
    private var boundsStartCenter: CGPoint {
        return CGPoint(x: startBounds.midX, y: startBounds.midY)
    }
    
    
    /**
     constraints has low priority
     */
    private var conWidth:  NSLayoutConstraint!
    private var conHeight: NSLayoutConstraint!
    
    private var startBounds: CGRect!
    private var startBackgroundColor: UIColor!
    private var startTitleColor: UIColor!
    
    private let prepareGroup = dispatch_group_create()
//    private let loadingGroup = dispatch_group_create()
    private let finishLoadingGroup = dispatch_group_create()
    
    
    
    // MARK: - UIButton
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupCommon()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupCommon()
    }
    
    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupCommon()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if crState == .Ready {
            layoutStartBounds()
            checkMarkLayer.position = boundsCenter
            
            if checkMarkLayer.superlayer == nil {
                checkMarkLayer.path = pathForMark().CGPath
                layer.addSublayer( checkMarkLayer )
            }
        }
        
        if crState == .Loading || crState == .Finishing{
            if layer.animationForKey( AnimKeys.bounds ) == nil {
                bounds = circleBounds
            }
        }
        
        layer.cornerRadius = bounds.midY
    }
    
    
    
    // MARK: - Public Methods
    public func resetToReady() {
        crState = .Ready
        borderLayer.removeAllAnimations()
        layer.removeAllAnimations()
        checkMarkLayer.removeAllAnimations()
        clearLayerContext()
        
        CATransaction.begin()
        CATransaction.setDisableActions( true )
        
        layer.backgroundColor = startBackgroundColor.CGColor
        
        checkMarkLayer.opacity = 0
        borderLayer.borderWidth = 0
        borderLayer.borderColor = crBorderColor.CGColor
        updateText()
        
        progressLayer.removeFromSuperlayer()
        progressLayer.strokeEnd = 0
        CATransaction.commit()
        setTitleColor(startTitleColor, forState: .Normal)
    }
    
    public func startAnimate() {
        if crState != .Ready {
            resetToReady()
        }
        
        crState = .Loading
    }
    
    public func stopAnimate() {
        guard crState != .Finishing && crState != .Finished else {
            return
        }
        crState = .Finishing
    }
    
    public func updateProgress(progress: CGFloat) {
        progressLayer.strokeEnd = progress
    }
    
    
    
    // MARK: - Selector && Action
    func touchUpInside(sender: CRNetworkButton) {
        guard crState != .Finished else {
            return
        }
        
        if animateOnTap {
            startAnimate()
        }
    }
}



// MARK: - Animation Delegate
extension CRNetworkButton {
    public override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        guard flag else {
            return
        }
        
        guard let contextRawValue = anim.valueForKey( Constants.contextID ) as? String else {
            return
        }
        
        let context = AnimContext(rawValue: contextRawValue)!
        switch context {
            
        case .LoadingStart:
            dispatch_group_leave( prepareGroup )
            
        case .Loading:
            break
            
        case .LoadingFinishing:
            dispatch_group_leave( finishLoadingGroup )
            
        }
    }
}



// MARK: - Private Methods
extension CRNetworkButton {
    
    private func layoutStartBounds() {
        startBounds = bounds
        borderLayer.bounds = startBounds
        borderLayer.cornerRadius = startBounds.midY
        borderLayer.position = CGPointMake(startBounds.midX, startBounds.midY)
    }
    
    private func completeAnimation() {
        self.updateText()
        self.enabled = true
        crState = .Finished
        
        if shouldAutoReverse {
            resetToReady()
        }
        
        completionHandler?()
        completionHandler = nil
    }
    
    
    
    // MARK: Setup
    private func setupCommon() {
        // we should use old swift syntax for pass validation of podspec
        addTarget(self, action: Selector("touchUpInside:"), //#selector(CRNetworkButton.touchUpInside(_:)),
                  forControlEvents: .TouchUpInside)
        
        contentEdgeInsets = UIEdgeInsets(top: 5,
                                         left: 20,
                                         bottom: 5,
                                         right: 20)
        setupButton()
        setupConstraints()
    }
    
    private func setupButton() {
        setTitle(startText, forState: .Normal)
        
        layer.cornerRadius  = bounds.midY
        layer.borderColor = crBorderColor.CGColor
        layer.addSublayer( borderLayer )
        
        startTitleColor = titleColorForState(.Normal)
        startBackgroundColor = backgroundColor
    }
    
    /** this method will add constraints for the width and height,
     constraint added for preventing change size according to intrinsic size
     */
    private func setupConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        
        conWidth = NSLayoutConstraint(item: self, attribute: .Width,
                                      relatedBy: .Equal, toItem: nil,
                                      attribute: .NotAnAttribute, multiplier: 1,
                                      constant: bounds.width)
        
        conHeight = NSLayoutConstraint(item: self, attribute: .Height,
                                       relatedBy: .Equal, toItem: nil,
                                       attribute: .NotAnAttribute, multiplier: 1,
                                       constant: bounds.height)
        
        conWidth.priority = UILayoutPriorityDefaultLow
        conHeight.priority = UILayoutPriorityDefaultLow
        
        NSLayoutConstraint.activateConstraints( [conWidth, conHeight] )
    }
    
    
    
    //MARK: Update
    private func updateText() {
        guard !shouldAutoReverse else {
            setTitle(startText, forState: .Normal)
            return
        }
        
        switch crState {
        case .Ready:
            setTitle(startText, forState: .Normal)
            
        case .Loading:
            fallthrough
            
        case .Finishing:
            fallthrough
            
        case .Finished:
            setTitle(endText, forState: .Normal)
        }
    }
    private func clearLayerContext() {
        for sublayer in layer.sublayers! {
            if sublayer == borderLayer || sublayer == checkMarkLayer {
                continue
            }
            if sublayer is CAShapeLayer {
                sublayer.removeFromSuperlayer()
            }
        }
    }
    
    
    
    // MARK: Managing
    private func handleCRState(state: CRState) {
        switch state {
            
        case .Ready:
            break
            
        case .Loading:
            updateText()
            enabled = false
            
            prepareLoadingAnimation({
                if self.progressMode {
                    self.startProgressLoadingAnimation()
                } else {
                    self.startLoadingAnimation()
                }
            })
            
        case .Finishing:
            finishAnimation()
            
        case .Finished:
            break
        }
    }
    
    
    
    // MARK: Animations Configuring
    
    // animate button to loading state, use completion to start loading animation
    private func prepareLoadingAnimation(completion: (()->())?) {
        let boundAnim = CABasicAnimation(keyPath: "bounds")
        boundAnim.toValue = NSValue(CGRect: circleBounds)
        
        let colorAnim = CABasicAnimation(keyPath: "backgroundColor")
        colorAnim.toValue = UIColor.whiteColor().CGColor
        
        let layerGroup = CAAnimationGroup()
        layerGroup.animations = [boundAnim,colorAnim]
        layerGroup.duration = Constants.prepareLoadingAnimDuration
        layerGroup.delegate = self
        layerGroup.fillMode = kCAFillModeForwards
        layerGroup.removedOnCompletion = false
        layerGroup.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        assignContext(.LoadingStart, anim: layerGroup)
        
        layer.addAnimation(layerGroup, forKey: AnimKeys.bounds)
        dispatch_group_enter( prepareGroup )
        
        
        let borderAnim = CABasicAnimation(keyPath: "borderWidth")
        borderAnim.toValue = crLineWidth
        
        let borderBounds = CABasicAnimation(keyPath: "bounds")
        borderBounds.toValue = NSValue(CGRect: circleBounds)
        
        let borderPosition = CABasicAnimation(keyPath: "position")
        borderPosition.toValue = NSValue(CGPoint: boundsCenter)
        
        let borderGroup = CAAnimationGroup()
        borderGroup.animations = [borderAnim,borderBounds,borderPosition]
        borderGroup.duration = Constants.prepareLoadingAnimDuration
        borderGroup.delegate = self
        borderGroup.fillMode = kCAFillModeForwards
        borderGroup.removedOnCompletion = false
        borderGroup.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        assignContext(.LoadingStart, anim: borderGroup)
        
        borderLayer.addAnimation(borderGroup, forKey: nil)
        dispatch_group_enter( prepareGroup )
        
        dispatch_group_notify(prepareGroup, dispatch_get_main_queue()) {
            self.borderLayer.borderWidth = self.crLineWidth
            self.borderLayer.bounds = self.circleBounds
            self.borderLayer.position = self.boundsCenter
            
            self.layer.backgroundColor = UIColor.whiteColor().CGColor
            self.bounds = self.circleBounds
            
            self.borderLayer.removeAllAnimations()
            self.layer.removeAllAnimations()
            
            completion?()
        }
        
        titleLabel?.layer.opacity = 0
        if !shouldAutoReverse {
            setTitleColor(crDotColor, forState: .Normal)
        }
    }
    
    // start default loading
    private func startLoadingAnimation() {
        let arCenter = boundsCenter
        let radius   = circleBounds.midX - crLineWidth / 2
        
        var lines = [CAShapeLayer]()
        let lineOffset:CGFloat = 2 * CGFloat(M_PI) / CGFloat(linesCount)
        
        for i in 0..<linesCount {
            let line = CAShapeLayer()
            let startAngle = lineOffset * CGFloat(i)
            
            line.path = UIBezierPath(arcCenter: arCenter,
                                     radius: radius,
                                     startAngle: startAngle,
                                     endAngle: startAngle + dotLength,
                                     clockwise: true).CGPath
            
            line.bounds = circleBounds
            line.strokeColor = crDotColor.CGColor
            line.lineWidth = crLineWidth
            line.fillColor = crDotColor.CGColor
            line.lineCap = kCALineCapRound
            
            layer.insertSublayer(line, above: borderLayer)
            line.position = arCenter
            lines.append( line )
        }
        
        let opacityAnim = CABasicAnimation(keyPath: "opacity")
        opacityAnim.fromValue = 0
        
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.byValue = NSNumber(double: 2*M_PI)
        rotation.duration = velocity
        rotation.repeatCount = Float.infinity
        
        for line in lines {
            line.addAnimation(rotation, forKey: "lineRotation")
            line.addAnimation(opacityAnim, forKey: nil)
        }
    }
    // start loading animation, that show progress
    private func startProgressLoadingAnimation() {
        progressLayer.position = boundsCenter
        layer.insertSublayer(progressLayer, above: borderLayer)
    }
    
    // last animations divided on 3 part, this part will start mechanism
    // 1nd part of finish animation
    private func finishAnimation() {
        layer.masksToBounds = true
        
        // lines
        let lines = layer.sublayers!.filter{
            
            guard $0 != checkMarkLayer && $0 != borderLayer else {
                return false
            }
            
            return $0 is CAShapeLayer
        }
        
        guard let line = lines.first as? CAShapeLayer
        where line.presentationLayer() != nil else {
            dotsScalingAnimation()
            return
        }
        
        // rotation for lines
        let rotation = CABasicAnimation(keyPath: "transform")
        rotation.toValue = NSValue(CATransform3D: CATransform3DIdentity)
        rotation.duration = Constants.finishLoadingAnimDuration
        rotation.delegate = self
        assignContext(.LoadingFinishing, anim: rotation)
        
        for line in lines {
            rotation.fromValue = NSValue(CATransform3D: (line.presentationLayer() as! CAShapeLayer).transform)
            line.addAnimation(rotation, forKey: "lineRotation")
            dispatch_group_enter( finishLoadingGroup )
        }
        
        dispatch_group_notify(finishLoadingGroup, dispatch_get_main_queue()) {
            self.dotsScalingAnimation()
        }
    }
    // 2nd part of finish animation
    private func dotsScalingAnimation() {
        // dot will scaling
        let animationScale = CABasicAnimation(keyPath: "transform.scale")
        animationScale.duration = Constants.resetLinesPositionAnimDuration
        animationScale.toValue = NSNumber(float: Float(bounds.height * 2/3))
        animationScale.removedOnCompletion = false
        animationScale.fillMode = kCAFillModeForwards
        animationScale.delegate = self
        assignContext(.LoadingFinishing, anim: animationScale)
        
        // dots will preparing
        let dotStartSize = CGSize(width: 2, height: 2)
        let angleOffset = 2*CGFloat(M_PI) / CGFloat(linesCount)
        let radius = circleBounds.midY - (crLineWidth * 2)
        
        var dots = [CAShapeLayer]()
        for i in 0..<linesCount {
            
            let angle = angleOffset * CGFloat(i) + (dotLength / 2)
            var dotPosition = CGPointMake(radius * cos(angle), radius * sin(angle))
            dotPosition.x += bounds.midX
            dotPosition.y += bounds.midY
            let dotRect = CGRect(origin: CGPointZero, size: dotStartSize)
            
            let dot = CAShapeLayer()
            dot.bounds = dotRect
            dot.position = dotPosition
            dot.fillColor = crDotColor.CGColor
            dot.path = UIBezierPath(ovalInRect: dot.bounds).CGPath
            dots.append(dot)
        }
        
        for dot in dots {
            self.layer.addSublayer( dot )
            dot.addAnimation(animationScale, forKey: "dotScale")
            dispatch_group_enter( finishLoadingGroup )
        }
        
        dispatch_group_notify( finishLoadingGroup , dispatch_get_main_queue()) {
            self.layer.backgroundColor = self.crDotColor.CGColor
            self.borderLayer.opacity = 0
            self.clearLayerContext()
            self.checkMarkAndBoundsAnimation()
        }
    }
    // 3nd part of finish animation
    private func checkMarkAndBoundsAnimation() {
        if shouldAutoReverse {
            borderLayer.borderWidth = 0
        }
        
        let totalTimeCheckMark = Constants.resetLinesPositionAnimDuration + Constants.checkMarkDelay
        
        let firstPart = totalTimeCheckMark / 100 * Constants.resetLinesPositionAnimDuration
        
        let opacityAnim = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnim.duration = Constants.resetLinesPositionAnimDuration
        opacityAnim.values = [0,1,1,0]
        opacityAnim.keyTimes = [0,
                                firstPart,
                                0.99,
                                1]
        opacityAnim.duration = totalTimeCheckMark
        
        checkMarkLayer.addAnimation(opacityAnim, forKey: nil)
        
        borderLayer.borderColor = crDotColor.CGColor
        borderLayer.opacity = 1
        
        layer.masksToBounds = false
        
        let proportions: [CGFloat] = [ circleBounds.width / startBounds.width, 1.2, 1, ]
        var bounces = [NSValue]()
        
        for i in 0..<proportions.count {
            let rect = CGRect(origin: startBounds.origin, size: CGSizeMake(startBounds.width * proportions[i], startBounds.height))
            bounces.append( NSValue(CGRect: rect) )
        }
        
        let borderBounce = CAKeyframeAnimation(keyPath: "bounds")
        borderBounce.keyTimes = [0,0.75,1]
        borderBounce.values = bounces
        borderBounce.duration = Constants.bounceDuration
        borderBounce.beginTime = CACurrentMediaTime() + opacityAnim.duration
        borderBounce.delegate = self
        borderBounce.removedOnCompletion = false
        borderBounce.fillMode = kCAFillModeBoth
        assignContext(.LoadingFinishing, anim: borderBounce)
        
        let borderPosition = CABasicAnimation(keyPath: "position")
        borderPosition.toValue = NSValue(CGPoint: boundsStartCenter)
        borderPosition.duration = Constants.bounceDuration * borderBounce.keyTimes![1].doubleValue
        borderPosition.beginTime = CACurrentMediaTime() + opacityAnim.duration
        borderPosition.delegate = self
        borderPosition.removedOnCompletion = false
        borderPosition.fillMode = kCAFillModeBoth
        assignContext(.LoadingFinishing, anim: borderPosition)
        
        borderLayer.addAnimation(borderBounce, forKey: nil)
        borderLayer.addAnimation(borderPosition, forKey: nil)
        
        dispatch_group_enter( finishLoadingGroup )
        dispatch_group_enter( finishLoadingGroup )
        
        
        let boundsAnim = CABasicAnimation(keyPath: "bounds")
        boundsAnim.fromValue = NSValue(CGRect: (layer.presentationLayer() as! CALayer).bounds)
        boundsAnim.toValue = NSValue(CGRect: startBounds)
        
        let colorAnim = CABasicAnimation(keyPath: "backgroundColor")
        colorAnim.toValue = (shouldAutoReverse ? startBackgroundColor : UIColor.whiteColor()).CGColor
        colorAnim.fromValue = crDotColor.CGColor
        
        let layerGroup = CAAnimationGroup()
        layerGroup.animations = [boundsAnim, colorAnim]
        
        layerGroup.duration = Constants.bounceDuration * borderBounce.keyTimes![1].doubleValue
        layerGroup.beginTime = borderBounce.beginTime
        layerGroup.delegate = self
        layerGroup.fillMode = kCAFillModeBoth
        layerGroup.removedOnCompletion = false
        assignContext(.LoadingFinishing, anim: layerGroup)
        
        layer.addAnimation(layerGroup, forKey: AnimKeys.bounds)
        layer.bounds = startBounds
        dispatch_group_enter( finishLoadingGroup )
        
        let opacityTitleAnim = CABasicAnimation(keyPath: "opacity")
        opacityTitleAnim.fromValue = 0
        opacityTitleAnim.toValue = 1
        opacityTitleAnim.duration = layerGroup.duration
        opacityTitleAnim.beginTime = layerGroup.beginTime
        opacityTitleAnim.fillMode = kCAFillModeBoth
        opacityTitleAnim.removedOnCompletion = false
        
        borderPosition.fromValue = NSValue(CGPoint: boundsCenter)
        dispatch_group_enter( finishLoadingGroup )
        
        titleLabel?.layer.addAnimation(opacityTitleAnim, forKey: "titleOpacityAnimation")
        titleLabel?.layer.addAnimation(borderPosition, forKey: "titlePosition")
        titleLabel?.layer.opacity = 1
        
        dispatch_group_notify(finishLoadingGroup , dispatch_get_main_queue()) {
            if self.shouldAutoReverse {
                self.layer.backgroundColor = self.startBackgroundColor.CGColor
                self.borderLayer.borderWidth = 0
            } else {
                self.layer.backgroundColor = UIColor.whiteColor().CGColor
            }
            
            self.borderLayer.position = self.boundsStartCenter
            self.borderLayer.bounds = self.startBounds
            
            self.titleLabel?.layer.removeAnimationForKey( "titleOpacityAnimation" )
            self.borderLayer.removeAllAnimations()
            self.layer.removeAllAnimations()
            
            self.completeAnimation()
        }
    }
    
    
    
    // MARK: Help Methods for animations
    private func createCheckMark() -> CAShapeLayer{
        // configure layer
        let checkmarkLayer = CAShapeLayer()
        checkmarkLayer.bounds = circleBounds
        checkmarkLayer.opacity = 0
        checkmarkLayer.fillColor = nil
        checkmarkLayer.strokeColor = UIColor.whiteColor().CGColor
        checkmarkLayer.lineCap = kCALineCapRound
        checkmarkLayer.lineJoin = kCALineJoinRound
        checkmarkLayer.lineWidth = crLineWidth / 2
        return checkmarkLayer
    }
    private func pathForMark() -> UIBezierPath {
        // geometry of the layer
        let percentShiftY:CGFloat = 0.3
        let percentShiftX:CGFloat = -0.1
        
        let firstRadius = 0.5 * circleBounds.midY
        let lastRadius  = 0.8 * circleBounds.midY
        
        let firstAngle  = CGFloat(-3 * M_PI_4)
        let lastAngle   = CGFloat(-1 * M_PI_4)
        
        var startPoint  = CGPoint(x: firstRadius * cos(firstAngle), y: firstRadius * sin(firstAngle))
        var midPoint    = CGPointZero
        var endPoint    = CGPoint(x: lastRadius * cos(lastAngle), y: lastRadius * sin(lastAngle))
        
        let correctedPoint = CGPointMake(boundsCenter.x + (boundsCenter.x * percentShiftX),
                                         boundsCenter.y + (boundsCenter.y * percentShiftY))
        
        startPoint.addPoint( correctedPoint )
        midPoint.addPoint( correctedPoint )
        endPoint.addPoint( correctedPoint )
        
        
        let path = UIBezierPath()
        path.moveToPoint( startPoint )
        path.addLineToPoint( midPoint )
        path.addLineToPoint( endPoint )
        return path
    }
    
    private func assignContext(context:AnimContext, anim: CAAnimation ) {
        anim.setValue(context.rawValue, forKey: Constants.contextID)
    }
    private func assignLayer(aLayer: CALayer, anim: CAAnimation) {
        anim.setValue(aLayer, forKey: Constants.layerAnimation)
    }
}



//MARK: CGPoint customization
extension CGPoint {
    private mutating func addPoint(point: CGPoint) {
        x += point.x
        y += point.y
    }
}


