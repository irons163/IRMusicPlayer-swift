Pod::Spec.new do |spec|
  spec.name         = "IRMusicPlayer-swift"
  spec.version      = "1.0.0"
  spec.summary      = "A powerful music player of iOS."
  spec.description  = "A powerful music player of iOS."
  spec.homepage     = "https://github.com/irons163/IRMusicPlayer-swift.git"
  spec.license      = "MIT"
  spec.author       = "irons163"
  spec.platform     = :ios, "11.0"
  spec.source       = { :git => "https://github.com/irons163/IRMusicPlayer-swift.git", :tag => spec.version.to_s }
  spec.source_files  = "IRMusicPlayer-swift/**/*.{h,m,swift}"
  spec.resources = ["IRMusicPlayer-swift/**/*.xib", "IRMusicPlayer-swift/**/*.xcassets"]
  spec.swift_version = '5.0'
end
