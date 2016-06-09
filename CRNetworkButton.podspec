
Pod::Spec.new do |s|
  s.name             = "CRNetworkButton"
  s.version          = "0.1.0"
  s.summary          = "Button with embedded animations of loading."

  s.description      = "Button with embedded animations of loading. Configurable loading animation, also has progress mode"

  s.homepage         = "https://redmine.cleveroad.com:4443/clrpods/CRNetworkButton"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Dmitry Pashinskiy" => "pashinskiy.kh.cr@gmail.com" }
  s.source           = { :git => "https://redmine.cleveroad.com:4443/clrpods/CRNetworkButton.git", :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'CRNetworkButton/Classes/**/*'
end
