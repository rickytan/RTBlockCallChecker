#
# Be sure to run `pod lib lint RTBlockCallChecker.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'RTBlockCallChecker'
  s.version          = '0.1.2'
  s.summary          = 'A helper utility to check if a block has been called'
  s.description      = <<-DESC
This project provide a tricky way to check if a block passed to a method has been
called.
                       DESC

  s.homepage         = 'https://github.com/rickytan/RTBlockCallChecker'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'rickytan' => 'ricky.tan.xin@gmail.com' }
  s.source           = { :git => 'https://github.com/rickytan/RTBlockCallChecker.git', :tag => s.version.to_s }


  s.ios.deployment_target = '8.0'
  s.requires_arc     = true
  s.source_files = 'RTBlockCallChecker/Classes/**/*'

  s.frameworks = 'Foundation'
end
