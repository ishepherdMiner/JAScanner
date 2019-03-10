Pod::Spec.new do |s|
  s.name         = 'JAScanner'
  s.version      = '0.0.1.1'
  s.summary      = '特性:扫描'
  s.description  = <<-DESC
  特性:扫描功能,支持QR
                   DESC
  s.homepage     = 'https://github.com/ishepherdMiner/JAScanner'
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Jason' => 'iJason92@yahoo.com' }
  s.platform     = :ios, '8.0'
  s.source       = { :git => 'ishepherdme@wangdl.synology.me:/var/services/homes/ishepherdme/git/components/feature/JAScanner.git', :tag => "#{s.version}" }
  s.source_files = 'JAScanner/**/**.{h,m}'  
  s.public_header_files = 'JAScanner/**/*.h'
  s.frameworks   = 'Foundation','UIKit', 'QuartzCore'
  s.requires_arc = true
  s.module_name  = 'JAScanner'
  # s.static_framework = true
  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # s.dependency "AFNetworking"
  s.resource = 'JAScanner/Scanner.bundle'

  s.dependency 'YYCategories'
  
  # s.xcconfig = { 'HEADER_SEARCH_PATHS' => '"$(SRCROOT)/../../../me/frameworks/JAProtocol/JAProtocol" ' + '"$(SRCROOT)/JAProtocol" ' + '"$(SRCROOT)/JAProtocol"'}
end
  
