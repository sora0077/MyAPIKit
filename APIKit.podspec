#
#  Be sure to run `pod spec lint APIKit.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.platform = :ios
  s.ios.deployment_target = '8.0'
  s.name         = "APIKit"
  s.version      = "2.0.3"
  s.summary      = "API Request Helper"

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
                   API Request Helper.
                   DESC

  s.homepage     = "https://github.com/sora0077/APIKit"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "" => "" }

  s.source       = { :git => "https://github.com/sora0077/APIKit.git", :tag => "#{s.version}" }

  s.source_files  = "APIKit/**/*.{swift}"
  s.exclude_files = "Classes/Exclude"

  s.dependency 'Alamofire'
  s.dependency 'BrightFutures'
end
