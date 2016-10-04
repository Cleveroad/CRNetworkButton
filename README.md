# CRNetworkButton [![Awesome](https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg)](https://github.com/sindresorhus/awesome) <img src="https://www.cleveroad.com/public/comercial/label-ios.svg" height="20"> <a href="https://www.cleveroad.com/?utm_source=github&utm_medium=label&utm_campaign=contacts"><img src="https://www.cleveroad.com/public/comercial/label-cleveroad.svg" height="20"></a>

[![CI Status](http://img.shields.io/travis/Dmitry Pashinskiy/CRNetworkButton.svg?style=flat)](https://travis-ci.org/Dmitry Pashinskiy/CRNetworkButton)
[![Version](https://img.shields.io/cocoapods/v/CRNetworkButton.svg?style=flat)](http://cocoapods.org/pods/CRNetworkButton)
[![License](https://img.shields.io/cocoapods/l/CRNetworkButton.svg?style=flat)](http://cocoapods.org/pods/CRNetworkButton)
[![Platform](https://img.shields.io/cocoapods/p/CRNetworkButton.svg?style=flat)](http://cocoapods.org/pods/CRNetworkButton)

![Header image](/images/header.png)

## Welcome to CRNetworkButton - Advanced Button Click Interaction

Meet a new iOS library from Cleveroad. Just in case you are sick and tired of ordinary button clicks throughout mobile apps, we can offer you something new and unique. From now on, anytime the user clicks on the button that involves addressing to the server, they will see the animation that informs them of the progress and  completion. This new engaging button click interaction is made possible with CRNetworkButton library. 


![Demo image](/images/demo_.gif)

If you strive to convey a clear message to your app users by means of buttons, you are more than welcome to ingrate your iOS app with CRNetworkButton library. Facilitate user’s interaction with your app!


[![Awesome](/images/logo-footer.png)](https://www.cleveroad.com/?utm_source=github&utm_medium=label&utm_campaign=contacts)
<br/>

## Requirements
* iOS 8 or higher

## Installation

CRNetworkButton is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "CRNetworkButton"
```
and run `pod install` in terminal.

```swift
import CRNetworkButton
```

## Setup 
CLNetworkButton uses all advantage of IB and it's feature of @IBInspectable and @IBDesignable. All of the necessary customization property is declared as @IBInspectable so you can setup it right from your storyboard. Also CLNetworkButton provides default values for all property, so you can just drag and drop it in your view and get ready to user network activity button.

## Usage
* Supports storyboards;
* Set `StartText` and `EndText`, it will shows on before animation and after, also you can set text for error state this text will be shown as a title in case of calling `stopByError()` by default this text is "Error".
* Set `shouldAutoreverse` to back in start state automatically.
* Set `animateOnTap` to true(by default is true), that allows you to start animation mechanism automatically then Touch Up Inside event react or use it manually

    ```swift
    @IBAction func buttonTapped(sender: CRNetworkButton) {
        sender.startAnimate()
    }
    ```
* Set `progressMode` to true, and use `updateProgress(progress: CGFloat)` to update current progress

    ```swift
    func downloadProgress(progress: CGFloat) {
        networkButton.updateProgress( progress )
    }
    ```
* To stop animation, call `stopAnimate()`. If proccess ends with error, call `stopByError()`. It will cause animation to stop with error style.
    
    ```swift
    @IBAction func buttonTapped(sender: CRNetworkButton) {
        SomeNetworkManager.performRequest(withSuccess: { (result) in
            sender.stopAnimate()
        }) { (error) in
            sender.stopByError()
        }
    }
    ```

<br />


## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.


## Support

If you have any other questions regarding the use of this library, please contact us for support at info@cleveroad.com (email subject: "CRNetworkButton. Support request.") 

<br />
## License
* * *
    The MIT License (MIT)
    
    Copyright (c) 2016 Cleveroad Inc.
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
