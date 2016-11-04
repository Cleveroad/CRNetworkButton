//
//  CRNetworkButton.swift
//  CRNetworkButton
//
//  Created by Dmitry Pashinskiy on 5/17/16.
//  Copyright © 2016 Cleveroad Inc. All rights reserved.
//

import UIKit


public enum CRState {
    case ready
    case loading
    case finishing
    case finished
}


private struct Constants {
    
    static let contextID   = "kAnimationIdentifier"
    static let layerAnimation = "kLayerAnimation"
    
    static let prepareLoadingAnimDuration: TimeInterval = 0.2
    static let resetLinesPositionAnimDuration: TimeInterval = 0.2
    static let finishLoadingAnimDuration: TimeInterval  = 0.3
    static let checkMarkDelay: TimeInterval  = 0.3
    static let bounceDuration: TimeInterval  = 0.3
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
open class CRNetworkButton: UIButton {
    
    // MARK: - Public variables
    
    /// measure in radians
    @IBInspectable open var dotLength: CGFloat = 0.1
    /// time for pass one lap
    @IBInspectable open var velocity: Double = 1
    /// lines count on loading state
    @IBInspectable open var linesCount: UInt = 2
    /// if set true, on tap will be called animation automatically
    @IBInspectable open var animateOnTap: Bool = true
    /// color of dots and line in loading state
    @IBInspectable open var crDotColor: UIColor = UIColor.green
    /// color for error stop
    @IBInspectable open var crErrorColor: UIColor = UIColor.red
    /// line width of the border
    @IBInspectable open var crLineWidth: CGFloat = 5
    /// after stop animate will set to default state
    @IBInspectable open var shouldAutoReverse: Bool = false
    /// allow to show progress, use **updateProgress** to manage button progress
    @IBInspectable open var progressMode: Bool = false
    /// border Color
    @IBInspectable open var crBorderColor: UIColor = UIColor.lightGray {
        didSet {
            borderLayer.borderColor = crBorderColor.cgColor
        }
    }
    @IBInspectable open var startText:String = "Go" {
        didSet {
            updateText()
        }
    }
    @IBInspectable open var endText:String = "Done" {
        didSet {
            updateText()
        }
    }
    
    @IBInspectable open var errorText:String = "Error"
    
    /// will clear after calling
    open var completionHandler: (()->())?
    
    open var currState: CRState {
        return crState
    }
    
    
    // MARK: - Private Vars
    fileprivate lazy var borderLayer: CALayer = {
        let layer =  CALayer()
        layer.borderWidth = 0
        layer.borderColor = self.crBorderColor.cgColor
        layer.backgroundColor = nil
        return layer
    }()
    
    fileprivate lazy var progressLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = nil
        layer.strokeColor = self.crDotColor.cgColor
        layer.bounds = self.circleBounds
        layer.path = UIBezierPath(arcCenter: self.boundsCenter, radius: self.boundsCenter.y - self.crLineWidth / 2,
                                  startAngle: CGFloat(-M_PI_2), endAngle: 3*CGFloat(M_PI_2), clockwise: true).cgPath
        
        layer.strokeEnd = 0
        layer.lineCap = kCALineCapRound
        layer.lineWidth = self.crLineWidth
        
        return layer
    }()
    
    fileprivate lazy var checkMarkLayer: CAShapeLayer = {
        return self.createCheckMark()
    }()
    
    fileprivate lazy var errorCrossMarkLayer: CAShapeLayer = {
       return self.createErrorCrossMark()
    }()
    
    fileprivate var crState: CRState = .ready {
        didSet {
            handleCRState( crState )
        }
    }
    
    fileprivate var circleBounds: CGRect {
        var newRect = startBounds
        newRect?.size.width = startBounds.height
        return newRect!
    }
    
    fileprivate var boundsCenter: CGPoint {
        return CGPoint(x: circleBounds.midX, y: circleBounds.midY)
    }
    
    fileprivate var boundsStartCenter: CGPoint {
        return CGPoint(x: startBounds.midX, y: startBounds.midY)
    }
    
    fileprivate var stopedByError:Bool = false
    
    
    /**
     constraints has low priority
     */
    fileprivate var conWidth:  NSLayoutConstraint!
    fileprivate var conHeight: NSLayoutConstraint!
    
    fileprivate var startBounds: CGRect!
    fileprivate var startBackgroundColor: UIColor!
    fileprivate var startTitleColor: UIColor!
    
    fileprivate let prepareGroup = DispatchGroup()
//    private let loadingGroup = dispatch_group_create()
    fileprivate let finishLoadingGroup = DispatchGroup()
    
    
    
    // MARK: - UIButton
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupCommon()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupCommon()
    }
    
    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupCommon()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        if crState == .ready {
            layoutStartBounds()
            checkMarkLayer.position = boundsCenter
            errorCrossMarkLayer.position = boundsCenter
            
            if checkMarkLayer.superlayer == nil {
                checkMarkLayer.path = pathForMark().cgPath
                layer.addSublayer( checkMarkLayer )
            }
            
            if errorCrossMarkLayer.superlayer == nil {
                errorCrossMarkLayer.path = pathForCrossMark().cgPath
                layer.addSublayer( errorCrossMarkLayer )
            }
        }
        
        if crState == .loading || crState == .finishing{
            if layer.animation( forKey: AnimKeys.bounds ) == nil {
                bounds = circleBounds
            }
        }
        
        layer.cornerRadius = bounds.midY
    }
    
    
    
    // MARK: - Public Methods
    open func resetToReady() {
        crState = .ready
        borderLayer.removeAllAnimations()
        layer.removeAllAnimations()
        checkMarkLayer.removeAllAnimations()
        errorCrossMarkLayer.removeAllAnimations()
        clearLayerContext()
        
        CATransaction.begin()
        CATransaction.setDisableActions( true )
        
        layer.backgroundColor = startBackgroundColor.cgColor
        
        checkMarkLayer.opacity = 0
        borderLayer.borderWidth = 0
        borderLayer.borderColor = crBorderColor.cgColor
        updateText()
        
        progressLayer.removeFromSuperlayer()
        progressLayer.strokeEnd = 0
        CATransaction.commit()
        setTitleColor(startTitleColor, for: UIControlState())
    }
    
    open func startAnimate() {
        if crState != .ready {
            resetToReady()
        }
        
        crState = .loading
    }
    
    open func stopAnimate() {
        guard crState != .finishing && crState != .finished else {
            return
        }
        crState = .finishing
    }
    
    open func stopByError() {
        stopedByError = true
        stopAnimate()
    }
    
    open func updateProgress(_ progress: CGFloat) {
        progressLayer.strokeEnd = progress
    }
    
    
    
    // MARK: - Selector && Action
    func touchUpInside(_ sender: CRNetworkButton) {
        guard crState != .finished else {
            return
        }
        
        if animateOnTap {
            startAnimate()
        }
    }
}



// MARK: - Animation Delegate
extension CRNetworkButton : CAAnimationDelegate {
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard flag else {
            return
        }
        
        guard let contextRawValue = anim.value( forKey: Constants.contextID ) as? String else {
            return
        }
        
        let context = AnimContext(rawValue: contextRawValue)!
        switch context {
            
        case .LoadingStart:
            prepareGroup.leave()
            
        case .Loading:
            break
            
        case .LoadingFinishing:
            finishLoadingGroup.leave()
            
        }
    }
}



// MARK: - Private Methods
extension CRNetworkButton {
    
    fileprivate func layoutStartBounds() {
        startBounds = bounds
        borderLayer.bounds = startBounds
        borderLayer.cornerRadius = startBounds.midY
        borderLayer.position = CGPoint(x: startBounds.midX, y: startBounds.midY)
    }
    
    fileprivate func completeAnimation() {
        self.updateText()
        self.isEnabled = true
        crState = .finished
        
        if shouldAutoReverse {
            resetToReady()
        }
        
        completionHandler?()
        completionHandler = nil
    }
    
    
    
    // MARK: Setup
    fileprivate func setupCommon() {
        // we should use old swift syntax for pass validation of podspec
        addTarget(self, action: #selector(CRNetworkButton.touchUpInside(_:)), //#selector(CRNetworkButton.touchUpInside(_:)),
                  for: .touchUpInside)
        
        contentEdgeInsets = UIEdgeInsets(top: 5,
                                         left: 20,
                                         bottom: 5,
                                         right: 20)
        setupButton()
        setupConstraints()
    }
    
    fileprivate func setupButton() {
        setTitle(startText, for: UIControlState())
        
        layer.cornerRadius  = bounds.midY
        layer.borderColor = crBorderColor.cgColor
        layer.addSublayer( borderLayer )
        
        startTitleColor = titleColor(for: UIControlState())
        startBackgroundColor = backgroundColor
    }
    
    /** this method will add constraints for the width and height,
     constraint added for preventing change size according to intrinsic size
     */
    fileprivate func setupConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        
        conWidth = NSLayoutConstraint(item: self, attribute: .width,
                                      relatedBy: .equal, toItem: nil,
                                      attribute: .notAnAttribute, multiplier: 1,
                                      constant: bounds.width)
        
        conHeight = NSLayoutConstraint(item: self, attribute: .height,
                                       relatedBy: .equal, toItem: nil,
                                       attribute: .notAnAttribute, multiplier: 1,
                                       constant: bounds.height)
        
        conWidth.priority = UILayoutPriorityDefaultLow
        conHeight.priority = UILayoutPriorityDefaultLow
        
        NSLayoutConstraint.activate( [conWidth, conHeight] )
    }
    
    
    
    //MARK: Update
    fileprivate func updateText() {
        guard !shouldAutoReverse else {
            setTitle(startText, for: UIControlState())
            return
        }
        
        switch crState {
        case .ready:
            setTitle(startText, for: UIControlState())
            
        case .loading:
            fallthrough
            
        case .finishing:
            fallthrough
            
        case .finished:
            setTitle(stopedByError ? errorText : endText, for: UIControlState())
        }
    }
    fileprivate func clearLayerContext() {
        for sublayer in layer.sublayers! {
            if sublayer == borderLayer || sublayer == checkMarkLayer || sublayer == errorCrossMarkLayer {
                continue
            }
            if sublayer is CAShapeLayer {
                sublayer.removeFromSuperlayer()
            }
        }
    }
    
    
    
    // MARK: Managing
    fileprivate func handleCRState(_ state: CRState) {
        switch state {
            
        case .ready:
            break
            
        case .loading:
            updateText()
            isEnabled = false
            
            prepareLoadingAnimation({
                if self.progressMode {
                    self.startProgressLoadingAnimation()
                } else {
                    self.startLoadingAnimation()
                }
            })
            
        case .finishing:
            finishAnimation()
            
        case .finished:
            if stopedByError {
                stopedByError = false
            }
            break
        }
    }
    
    
    
    // MARK: Animations Configuring
    
    // animate button to loading state, use completion to start loading animation
    fileprivate func prepareLoadingAnimation(_ completion: (()->())?) {
        let boundAnim = CABasicAnimation(keyPath: "bounds")
        boundAnim.toValue = NSValue(cgRect: circleBounds)
        
        let colorAnim = CABasicAnimation(keyPath: "backgroundColor")
        colorAnim.toValue = UIColor.white.cgColor
        
        let layerGroup = CAAnimationGroup()
        layerGroup.animations = [boundAnim,colorAnim]
        layerGroup.duration = Constants.prepareLoadingAnimDuration
        layerGroup.delegate = self
        layerGroup.fillMode = kCAFillModeForwards
        layerGroup.isRemovedOnCompletion = false
        layerGroup.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        assignContext(.LoadingStart, anim: layerGroup)
        
        layer.add(layerGroup, forKey: AnimKeys.bounds)
        prepareGroup.enter()
        
        
        let borderAnim = CABasicAnimation(keyPath: "borderWidth")
        borderAnim.toValue = crLineWidth
        
        let borderBounds = CABasicAnimation(keyPath: "bounds")
        borderBounds.toValue = NSValue(cgRect: circleBounds)
        
        let borderPosition = CABasicAnimation(keyPath: "position")
        borderPosition.toValue = NSValue(cgPoint: boundsCenter)
        
        let borderGroup = CAAnimationGroup()
        borderGroup.animations = [borderAnim,borderBounds,borderPosition]
        borderGroup.duration = Constants.prepareLoadingAnimDuration
        borderGroup.delegate = self
        borderGroup.fillMode = kCAFillModeForwards
        borderGroup.isRemovedOnCompletion = false
        borderGroup.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        assignContext(.LoadingStart, anim: borderGroup)
        
        borderLayer.add(borderGroup, forKey: nil)
        prepareGroup.enter()
        
        prepareGroup.notify(queue: DispatchQueue.main) {
            self.borderLayer.borderWidth = self.crLineWidth
            self.borderLayer.bounds = self.circleBounds
            self.borderLayer.position = self.boundsCenter
            
            self.layer.backgroundColor = UIColor.white.cgColor
            self.bounds = self.circleBounds
            
            self.borderLayer.removeAllAnimations()
            self.layer.removeAllAnimations()
            
            completion?()
        }
        
        titleLabel?.layer.opacity = 0
        if !shouldAutoReverse {
            setTitleColor(crDotColor, for: UIControlState())
        }
    }
    
    // start default loading
    fileprivate func startLoadingAnimation() {
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
                                     clockwise: true).cgPath
            
            line.bounds = circleBounds
            line.strokeColor = crDotColor.cgColor
            line.lineWidth = crLineWidth
            line.fillColor = crDotColor.cgColor
            line.lineCap = kCALineCapRound
            
            layer.insertSublayer(line, above: borderLayer)
            line.position = arCenter
            lines.append( line )
        }
        
        let opacityAnim = CABasicAnimation(keyPath: "opacity")
        opacityAnim.fromValue = 0
        
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.byValue = NSNumber(value: 2*M_PI as Double)
        rotation.duration = velocity
        rotation.repeatCount = Float.infinity
        
        for line in lines {
            line.add(rotation, forKey: "lineRotation")
            line.add(opacityAnim, forKey: nil)
        }
    }
    // start loading animation, that show progress
    fileprivate func startProgressLoadingAnimation() {
        progressLayer.position = boundsCenter
        layer.insertSublayer(progressLayer, above: borderLayer)
    }
    
    // last animations divided on 3 part, this part will start mechanism
    // 1nd part of finish animation
    fileprivate func finishAnimation() {
        layer.masksToBounds = true
        
        // lines
        let lines = layer.sublayers!.filter{
            
            guard $0 != checkMarkLayer && $0 != borderLayer else {
                return false
            }
            
            return $0 is CAShapeLayer
        }
        
        guard let line = lines.first as? CAShapeLayer, line.presentation() != nil else {
            dotsScalingAnimation()
            return
        }
        
        // rotation for lines
        let rotation = CABasicAnimation(keyPath: "transform")
        rotation.toValue = NSValue(caTransform3D: CATransform3DIdentity)
        rotation.duration = Constants.finishLoadingAnimDuration
        rotation.delegate = self
        assignContext(.LoadingFinishing, anim: rotation)
        
        for line in lines {
            rotation.fromValue = NSValue(caTransform3D: (line.presentation() as! CAShapeLayer).transform)
            line.add(rotation, forKey: "lineRotation")
            finishLoadingGroup.enter()
        }
        
        finishLoadingGroup.notify(queue: DispatchQueue.main) {
            self.dotsScalingAnimation()
        }
    }
    // 2nd part of finish animation
    fileprivate func dotsScalingAnimation() {
        // dot will scaling
        let animationScale = CABasicAnimation(keyPath: "transform.scale")
        animationScale.duration = Constants.resetLinesPositionAnimDuration
        animationScale.toValue = NSNumber(value: Float(bounds.height * 2/3) as Float)
        animationScale.isRemovedOnCompletion = false
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
            var dotPosition = CGPoint(x: radius * cos(angle), y: radius * sin(angle))
            dotPosition.x += bounds.midX
            dotPosition.y += bounds.midY
            let dotRect = CGRect(origin: CGPoint.zero, size: dotStartSize)
            
            let dot = CAShapeLayer()
            dot.bounds = dotRect
            dot.position = dotPosition
            dot.fillColor = stopedByError ? crErrorColor.cgColor : crDotColor.cgColor
            dot.path = UIBezierPath(ovalIn: dot.bounds).cgPath
            dots.append(dot)
        }
        
        for dot in dots {
            self.layer.addSublayer( dot )
            dot.add(animationScale, forKey: "dotScale")
            finishLoadingGroup.enter()
        }
        
        finishLoadingGroup.notify(queue: DispatchQueue.main) {
            self.layer.backgroundColor = self.stopedByError ? self.crErrorColor.cgColor : self.crDotColor.cgColor
            self.borderLayer.opacity = 0
            self.clearLayerContext()
            self.checkMarkAndBoundsAnimation()
        }
    }
    // 3nd part of finish animation
    fileprivate func checkMarkAndBoundsAnimation() {
        if shouldAutoReverse {
            borderLayer.borderWidth = 0
        }
        
        let totalTimeCheckMark = Constants.resetLinesPositionAnimDuration + Constants.checkMarkDelay
        
        let firstPart = totalTimeCheckMark / 100 * Constants.resetLinesPositionAnimDuration
        
        let opacityAnim = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnim.duration = Constants.resetLinesPositionAnimDuration
        opacityAnim.values = [0,1,1,0]
        opacityAnim.keyTimes = [0,
                                NSNumber(value: firstPart),
                                0.99,
                                1]
        opacityAnim.duration = totalTimeCheckMark
        
        stopedByError ? errorCrossMarkLayer.add(opacityAnim, forKey: nil) : checkMarkLayer.add(opacityAnim, forKey: nil)
        updateText()
        if stopedByError {
            setTitleColor(crErrorColor, for: UIControlState())
        }
        borderLayer.borderColor = stopedByError ? crErrorColor.cgColor : crDotColor.cgColor
        borderLayer.opacity = 1
        
        layer.masksToBounds = false
        
        let proportions: [CGFloat] = [ circleBounds.width / startBounds.width, 1.2, 1, ]
        var bounces = [NSValue]()
        
        for i in 0..<proportions.count {
            let rect = CGRect(origin: startBounds.origin, size: CGSize(width: startBounds.width * proportions[i], height: startBounds.height))
            bounces.append( NSValue(cgRect: rect) )
        }
        
        let borderBounce = CAKeyframeAnimation(keyPath: "bounds")
        borderBounce.keyTimes = [0,0.75,1]
        borderBounce.values = bounces
        borderBounce.duration = Constants.bounceDuration
        borderBounce.beginTime = CACurrentMediaTime() + opacityAnim.duration
        borderBounce.delegate = self
        borderBounce.isRemovedOnCompletion = false
        borderBounce.fillMode = kCAFillModeBoth
        assignContext(.LoadingFinishing, anim: borderBounce)
        
        let borderPosition = CABasicAnimation(keyPath: "position")
        borderPosition.toValue = NSValue(cgPoint: boundsStartCenter)
        borderPosition.duration = Constants.bounceDuration * borderBounce.keyTimes![1].doubleValue
        borderPosition.beginTime = CACurrentMediaTime() + opacityAnim.duration
        borderPosition.delegate = self
        borderPosition.isRemovedOnCompletion = false
        borderPosition.fillMode = kCAFillModeBoth
        assignContext(.LoadingFinishing, anim: borderPosition)
        
        borderLayer.add(borderBounce, forKey: nil)
        borderLayer.add(borderPosition, forKey: nil)
        
        finishLoadingGroup.enter()
        finishLoadingGroup.enter()
        
        
        let boundsAnim = CABasicAnimation(keyPath: "bounds")
        boundsAnim.fromValue = NSValue(cgRect: (layer.presentation()!).bounds)
        boundsAnim.toValue = NSValue(cgRect: startBounds)
        
        let colorAnim = CABasicAnimation(keyPath: "backgroundColor")
        colorAnim.toValue = (shouldAutoReverse ? startBackgroundColor : UIColor.white).cgColor
        colorAnim.fromValue = stopedByError ? crErrorColor : crDotColor.cgColor
        
        let layerGroup = CAAnimationGroup()
        layerGroup.animations = [boundsAnim, colorAnim]
        
        layerGroup.duration = Constants.bounceDuration * borderBounce.keyTimes![1].doubleValue
        layerGroup.beginTime = borderBounce.beginTime
        layerGroup.delegate = self
        layerGroup.fillMode = kCAFillModeBoth
        layerGroup.isRemovedOnCompletion = false
        assignContext(.LoadingFinishing, anim: layerGroup)
        
        layer.add(layerGroup, forKey: AnimKeys.bounds)
        layer.bounds = startBounds
        finishLoadingGroup.enter()
        
        let opacityTitleAnim = CABasicAnimation(keyPath: "opacity")
        opacityTitleAnim.fromValue = 0
        opacityTitleAnim.toValue = 1
        opacityTitleAnim.duration = layerGroup.duration
        opacityTitleAnim.beginTime = layerGroup.beginTime
        opacityTitleAnim.fillMode = kCAFillModeBoth
        opacityTitleAnim.isRemovedOnCompletion = false
        
        borderPosition.fromValue = NSValue(cgPoint: boundsCenter)
        finishLoadingGroup.enter()
        
        titleLabel?.layer.add(opacityTitleAnim, forKey: "titleOpacityAnimation")
        titleLabel?.layer.add(borderPosition, forKey: "titlePosition")
        titleLabel?.layer.opacity = 1
        
        finishLoadingGroup.notify(queue: DispatchQueue.main) {
            if self.shouldAutoReverse {
                self.layer.backgroundColor = self.startBackgroundColor.cgColor
                self.borderLayer.borderWidth = 0
            } else {
                self.layer.backgroundColor = UIColor.white.cgColor
            }
            
            self.borderLayer.position = self.boundsStartCenter
            self.borderLayer.bounds = self.startBounds
            
            self.titleLabel?.layer.removeAnimation( forKey: "titleOpacityAnimation" )
            self.borderLayer.removeAllAnimations()
            self.layer.removeAllAnimations()
            
            self.completeAnimation()
        }
    }
    
    
    
    // MARK: Help Methods for animations
    fileprivate func createMarkLayer() -> CAShapeLayer {
        // configure layer
        let layer         = CAShapeLayer()
        layer.bounds      = circleBounds
        layer.opacity     = 0
        layer.fillColor   = nil
        layer.strokeColor = UIColor.white.cgColor
        layer.lineCap     = kCALineCapRound
        layer.lineJoin    = kCALineJoinRound
        layer.lineWidth   = crLineWidth / 2
        
        return layer
    }
    
    fileprivate func createErrorCrossMark() -> CAShapeLayer {
        let crossmarkLayer = createMarkLayer()
        return crossmarkLayer
    }
    
    fileprivate func createCheckMark() -> CAShapeLayer {
        let checkmarkLayer = createMarkLayer()
        return checkmarkLayer
    }
    fileprivate func pathForMark() -> UIBezierPath {
        // geometry of the layer
        let percentShiftY:CGFloat = 0.3
        let percentShiftX:CGFloat = -0.1
        
        let firstRadius = 0.5 * circleBounds.midY
        let lastRadius  = 0.8 * circleBounds.midY
        
        let firstAngle  = CGFloat(-3 * M_PI_4)
        let lastAngle   = CGFloat(-1 * M_PI_4)
        
        var startPoint  = CGPoint(x: firstRadius * cos(firstAngle), y: firstRadius * sin(firstAngle))
        var midPoint    = CGPoint.zero
        var endPoint    = CGPoint(x: lastRadius * cos(lastAngle), y: lastRadius * sin(lastAngle))
        
        let correctedPoint = CGPoint(x: boundsCenter.x + (boundsCenter.x * percentShiftX),
                                         y: boundsCenter.y + (boundsCenter.y * percentShiftY))
        
        startPoint.addPoint( correctedPoint )
        midPoint.addPoint( correctedPoint )
        endPoint.addPoint( correctedPoint )
        
        
        let path = UIBezierPath()
        path.move( to: startPoint )
        path.addLine( to: midPoint )
        path.addLine( to: endPoint )
        return path
    }
    
    fileprivate func pathForCrossMark() -> UIBezierPath {
        // geometry for crossmark layer
        let XShift:CGFloat = 10
        let YShift:CGFloat = 10
        
        let firstStartPoint  = CGPoint(x: XShift, y: YShift)
        let firstEndPoint    = CGPoint(x: circleBounds.maxX - XShift, y: circleBounds.maxY - XShift)
        let secondStartPoint = CGPoint(x: circleBounds.maxX - XShift, y: circleBounds.minY + YShift)
        let secondEndPoint   = CGPoint(x: circleBounds.minX + XShift, y: circleBounds.maxY - YShift)
        
        let path = UIBezierPath()
        path.move(to: firstStartPoint)
        path.addLine(to: firstEndPoint)
        path.move(to: secondStartPoint)
        path.addLine(to: secondEndPoint)
        return path
    }
    
    fileprivate func assignContext(_ context:AnimContext, anim: CAAnimation ) {
        anim.setValue(context.rawValue, forKey: Constants.contextID)
    }
    fileprivate func assignLayer(_ aLayer: CALayer, anim: CAAnimation) {
        anim.setValue(aLayer, forKey: Constants.layerAnimation)
    }
}



//MARK: CGPoint customization
extension CGPoint {
    fileprivate mutating func addPoint(_ point: CGPoint) {
        x += point.x
        y += point.y
    }
}


