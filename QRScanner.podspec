
Pod::Spec.new do |s|
  s.name             = 'QRScanner'
  s.version          = '1.0'
  s.swift_version    = '4.0'
  s.summary          = 'QRScanner in RxSwift way'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage = "https://github.com/hamzaansari09/HACameraView"
  s.author = { "Hamza Ansari" => "hamzaansari209@gmail.com" }
  s.source = { :tag => s.version }

  s.ios.deployment_target = '9.0'
  s.source_files = 'Classes/**/*'

  s.resource_bundles = {
    'QRScanner' => ['Assets/*.png']
  }

  s.dependency 'RxSwift', '~> 4.0'
  s.dependency 'RxCocoa', '~> 4.0'
end
