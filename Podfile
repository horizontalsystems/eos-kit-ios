platform :ios, '12.0'
use_frameworks!

inhibit_all_warnings!

workspace 'EosKit'

project 'EosKit/EosKit'
project 'EosKitDemo/EosKitDemo'

def common_pods
  pod 'RxSwift', '~> 5.0'
  pod 'GRDB.swift', '~> 4.0'
  pod 'Alamofire', '~> 4.0'

  pod 'EosioSwift', git: 'https://github.com/horizontalsystems/eosio-swift'
  pod 'EosioSwiftAbieosSerializationProvider', '~> 0.1.1'
  pod 'EosioSwiftSoftkeySignatureProvider', '~> 0.1.1'
end

def test_pods
  pod 'Cuckoo'
  pod 'Quick'
  pod 'Nimble'
end

target :EosKit do
  project 'EosKit/EosKit'

  common_pods
end

target :EosKitDemo do
  project 'EosKitDemo/EosKitDemo'
  common_pods
end

target :EosKitTests do
  project 'EosKit/EosKit'
  test_pods
end
