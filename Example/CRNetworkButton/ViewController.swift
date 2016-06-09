//
//  ViewController.swift
//  CRNetworkButton
//
//  Created by Dmitry Pashinskiy on 5/17/16.
//  Copyright © 2016 Cleveroad Inc. All rights reserved.
//

import UIKit
import CRNetworkButton

class ViewController: UIViewController {
    
    @IBOutlet weak var button: CRNetworkButton!
    
    var progress: CGFloat = 0
    var timer: NSTimer?
    let requestDuration = 4.0
    let frequencyUpdate = 0.01
    
    lazy var progressPerFrequency: CGFloat = {
        let progressPerSecond = 1.0 / self.requestDuration
        return CGFloat(progressPerSecond * self.frequencyUpdate)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    
    func updateProgress() {
        guard progress <= 1 else {
            timer?.invalidate()
            button.stopAnimate()
            progress = 0
            return
        }
        
        progress += progressPerFrequency//0.005
        button.updateProgress( progress )
    }
}



//MARK: - Action
extension ViewController {
    @IBAction func topButtonTapped(sender: CRNetworkButton) {
        guard !sender.selected else {
            if sender.currState == .Finished {
                sender.resetToReady()
                sender.selected = false
            }
            return
        }
        
        sender.selected = true
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2*NSEC_PER_SEC)), dispatch_get_main_queue()) {
            sender.stopAnimate()
        }
    }
    
    @IBAction func secondButtonTapped(sender: CRNetworkButton) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2*NSEC_PER_SEC)), dispatch_get_main_queue()) {
            sender.stopAnimate()
        }
    }
    
    @IBAction func buttonTapped(sender: CRNetworkButton) {
        timer?.invalidate()
        timer = NSTimer.scheduledTimerWithTimeInterval(frequencyUpdate, target:self, selector: #selector(ViewController.updateProgress),
                                                       userInfo: nil, repeats: true)
    }
}