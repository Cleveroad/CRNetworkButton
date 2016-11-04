
Pod::Spec.new do |s|
  s.name             = "CRNetworkButton"
  s.version          = "1.0.2"
  s.summary          = "Button with embedded animations of loading."
  s.description      = <<-DESC
"Button with embedded animations of loading. Configurable loading animation, also has progress mode"
DESC

  s.homepage         = "https://github.com/Cleveroad/CRNetworkButton"
  s.screenshots       = "https://raw.githubusercontent.com/Cleveroad/CRNetworkButton/master/images/header.png", "https://raw.githubusercontent.com/Cleveroad/CRNetworkButton/master/images/demo_.gif"
  s.license          = 'MIT'
  s.author           = { "Cleveroad" => "info@cleveroad.com" }
  s.source           = { :git => "https://github.com/Cleveroad/CRNetworkButton.git", :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'CRNetworkButton/Classes/**/*'
end
