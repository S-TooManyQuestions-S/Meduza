Pod::Spec.new do |spec|

  spec.name         = "Meduza"
  spec.version      = '1.0.0'
  spec.summary      = "iOS Snapshot library"

  spec.homepage     = "https://github.com/S-TooManyQuestions-S/Meduza.git"
  spec.source       = { :git => "https://github.com/S-TooManyQuestions-S/Meduza.git",
                        :tag => spec.version.to_s }
  spec.author       = { "Andrew Samarenko" => "toomanyquestions@yandex.ru" }

  spec.pod_target_xcconfig = { "ENABLE_TESTING_SEARCH_PATHS" => "YES" }

  spec.ios.deployment_target = '15.0'
  spec.swift_version = '5.4'

  spec.frameworks   = 'XCTest','UIKit','Foundation'

  spec.source_files = 'Core/Classes/**/*.swift'
end
