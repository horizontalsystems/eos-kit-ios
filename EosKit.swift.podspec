Pod::Spec.new do |spec|
  spec.name = 'EosKit.swift'
  spec.module_name = 'EosKit'
  spec.version = '0.3.1'
  spec.summary = 'EOS blockchain library for Swift'
  spec.description = <<-DESC
                       Eos.swift implements EOS protocol in Swift.
                       ```
                    DESC
  spec.homepage = 'https://github.com/horizontalsystems/eos-kit-ios'
  spec.license = { :type => 'Apache 2.0', :file => 'LICENSE' }
  spec.author = { 'Horizontal Systems' => 'hsdao@protonmail.ch' }
  spec.social_media_url = 'http://horizontalsystems.io/'

  spec.requires_arc = true
  spec.source = { git: 'https://github.com/horizontalsystems/eos-kit-ios.git', tag: "#{spec.version}" }
  spec.source_files = 'EosKit/EosKit/**/*.{h,m,swift}'
  spec.ios.deployment_target = '12.0'
  spec.swift_version = '5'

  spec.dependency 'RxSwift', '~> 5.0'
  spec.dependency 'GRDB.swift', '~> 4.0'
  spec.dependency 'Alamofire', '~> 4.0'

  spec.dependency 'EosioSwift', '~> 0.2.1'
  spec.dependency 'EosioSwiftAbieosSerializationProvider', '~> 0.2.1'
  spec.dependency 'EosioSwiftSoftkeySignatureProvider', '~> 0.2.1'
end
