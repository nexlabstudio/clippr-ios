Pod::Spec.new do |s|
  s.name             = 'ClipprSDK'
  s.version          = '0.0.4'
  s.summary          = 'Deep linking and mobile attribution SDK for iOS'
  s.description      = <<-DESC
    Clippr SDK provides seamless deep linking and attribution for iOS apps.
    Features include:
    - Universal Links handling
    - Deferred deep linking
    - Attribution tracking
    - Custom event tracking
  DESC

  s.homepage         = 'https://useclippr.xyz'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Clippr' => 'engr@nexlab.studio' }
  s.source           = { :git => 'https://github.com/nexlabstudio/clippr-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.7'

  s.source_files = 'Sources/ClipprSDK/**/*'
  
  s.frameworks = 'UIKit', 'Foundation', 'Security', 'AdSupport', 'AppTrackingTransparency'
end
