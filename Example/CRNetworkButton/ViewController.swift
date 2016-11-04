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
    @IBOutlet weak var failableButtton: CRNetworkButton!
    
    var progress: CGFloat = 0
    var timer: Timer?
    let requestDuration = 4.0
    let frequencyUpdate = 0.01
    var failureCounter = 0
    
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
    @IBAction func topButtonTapped(_ sender: CRNetworkButton) {
        guard !sender.isSelected else {
            if sender.currState == .finished {
                sender.resetToReady()
                sender.isSelected = false
            }
            return
        }
        
        sender.isSelected = true
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(2*NSEC_PER_SEC)) / Double(NSEC_PER_SEC)) {
            sender.stopAnimate()
        }
    }
    
    @IBAction func secondButtonTapped(_ sender: CRNetworkButton) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(2*NSEC_PER_SEC)) / Double(NSEC_PER_SEC)) {
            sender.stopAnimate()
        }
    }
    
    @IBAction func buttonTapped(_ sender: CRNetworkButton) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: frequencyUpdate, target:self, selector: #selector(ViewController.updateProgress),
                                                       userInfo: nil, repeats: true)
    }
    
    @IBAction func failableButtonTapped(_ sender: CRNetworkButton) {
        guard !sender.isSelected else {
            if sender.currState == .finished {
                sender.resetToReady()
                sender.isSelected = false
            }
            return
        }
        
        sender.isSelected = true
        FakeNetworkManager.performRequest(withSuccess: { (result) in
            sender.stopAnimate()
            }) { (error) in
            sender.stopByError()
        }
    }
}
