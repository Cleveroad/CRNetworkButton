//
//  FakeNetworkManager.swift
//  CRNetworkButton
//
//  Created by Vladyslav Denysenko on 9/9/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

class FakeNetworkManager {
    
    static var shouldImitateError:Bool = true
    
    class func performRequest(withSuccess succes:((String)->Void)?, error:((NSError)->Void)?) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(2*NSEC_PER_SEC)) / Double(NSEC_PER_SEC)) {
            
            if shouldImitateError {
                error?(NSError(domain: "com.fake.error", code: 1, userInfo: ["message":"Fake error to test network button error state"]))
            } else {
                succes?("Faek success")
            }
            
            shouldImitateError = !shouldImitateError
        }
    }
}
