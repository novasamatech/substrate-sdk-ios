#
# Be sure to run `pod lib lint SubstrateSdk.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SubstrateSdk'
  s.version          = '4.0.3'
  s.summary          = 'Utility library that implements clients specific logic to interact with substrate based networks'

  s.homepage         = 'https://github.com/nova-wallet/substrate-sdk-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ERussel' => 'ruslan@novawallet.io' }
  s.source           = { :git => 'https://github.com/nova-wallet/substrate-sdk-ios.git', :tag => s.version.to_s }
  s.swift_version    = '5.0'

  s.ios.deployment_target = '14.0'

  s.source_files = 'SubstrateSdk/Classes/**/*'
  s.dependency 'NovaCrypto/sr25519', '~> 0.1.0'
  s.dependency 'NovaCrypto/ed25519', '~> 0.1.0'
  s.dependency 'NovaCrypto/secp256k1', '~> 0.1.0'
  s.dependency 'NovaCrypto/Scrypt', '~> 0.1.0'
  s.dependency 'NovaCrypto/ss58', '~> 0.1.0'
  s.dependency 'ReachabilitySwift', '~> 5.2.4'
  s.dependency 'Operation-iOS', '~> 2.1.0'
  s.dependency 'Starscream'
  s.dependency 'TweetNacl', '~> 1.0.0'
  s.dependency 'BigInt', '~> 5.0'
  s.dependency 'xxHash-Swift', '~> 1.0.0'
  s.dependency 'keccak.c', '~> 0.1.0'
  
  s.test_spec do |ts|
      ts.source_files = 'Tests/**/*.swift'
      ts.resources = ['Tests/**/*.json', 'Tests/**/*-metadata']
  end
end
