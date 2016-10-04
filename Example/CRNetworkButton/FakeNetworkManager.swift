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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2*NSEC_PER_SEC)), dispatch_get_main_queue()) {
            
            if shouldImitateError {
                error?(NSError(domain: "com.fake.error", code: 1, userInfo: ["message":"Fake error to test network button error state"]))
            } else {
                succes?("Faek success")
            }
            
            shouldImitateError = !shouldImitateError
        }
    }
}
