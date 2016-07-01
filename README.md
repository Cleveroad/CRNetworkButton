# CRNetworkButton [![Awesome](https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg)](https://github.com/sindresorhus/awesome) <img src="https://www.cleveroad.com/public/comercial/label-ios.svg" height="20"> <a href="https://www.cleveroad.com/?utm_source=github&utm_medium=label&utm_campaign=contacts"><img src="https://www.cleveroad.com/public/comercial/label-cleveroad.svg" height="20"></a>

[![CI Status](http://img.shields.io/travis/Dmitry Pashinskiy/CRNetworkButton.svg?style=flat)](https://travis-ci.org/Dmitry Pashinskiy/CRNetworkButton)
[![Version](https://img.shields.io/cocoapods/v/CRNetworkButton.svg?style=flat)](http://cocoapods.org/pods/CRNetworkButton)
[![License](https://img.shields.io/cocoapods/l/CRNetworkButton.svg?style=flat)](http://cocoapods.org/pods/CRNetworkButton)
[![Platform](https://img.shields.io/cocoapods/p/CRNetworkButton.svg?style=flat)](http://cocoapods.org/pods/CRNetworkButton)

![Header image](/images/header.png)

## Welcome to CRNetworkButton - header text.

Text1


![Demo image](/images/demo.gif)


Text2

[![Article image](/images/article.jpg)](https://www.cleveroad.com/blog/case-study-audio-visualization-view-for-android-by-cleveroad)
<br/><br/>
[![Awesome](/images/logo-footer.png)](https://www.cleveroad.com/?utm_source=github&utm_medium=label&utm_campaign=contacts)
<br/>
## Setup and usage

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

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

## Usage
* Supports storyboards;
* Set `StartText` and `EndText`, it will shows on before animation and after.
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


<br />
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



# CRNetworkButton





