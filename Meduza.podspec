Pod::Spec.new do |spec|

  spec.name         = "Meduza"
  spec.version      = '1.0.0'
  spec.summary      = "iOS Snapshot library"
  spec.license      = { type: 'MIT', file: 'LICENSE' }

  spec.homepage     = "https://github.com/S-TooManyQuestions-S/Meduza"
  spec.source       = { :git => "https://github.com/S-TooManyQuestions-S/Meduza.git", :tag => spec.version.to_s }
  spec.author       = { "Andrew Samarenko" => "toomanyquestions@yandex.ru" }

  spec.pod_target_xcconfig = { "ENABLE_TESTING_SEARCH_PATHS" => "YES" }

  spec.static_framework = true
  spec.prefix_header_file = false
  spec.ios.deployment_target = '15.0'
  spec.swift_version = '5.0'


  spec.source_files = 'Development/Classes/**/*.swift'
end
