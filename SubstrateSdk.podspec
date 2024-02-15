#
# Be sure to run `pod lib lint SubstrateSdk.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SubstrateSdk'
  s.version          = '1.17.0'
  s.summary          = 'Utility library that implements clients specific logic to interact with substrate based networks'

  s.homepage         = 'https://github.com/nova-wallet/substrate-sdk-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ERussel' => 'ruslan@novawallet.io' }
  s.source           = { :git => 'https://github.com/nova-wallet/substrate-sdk-ios.git', :tag => s.version.to_s }
  s.swift_version    = '5.0'

  s.ios.deployment_target = '11.0'

  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64', 'VALID_ARCHS' => 'x86_64 armv7 arm64'  }

  s.source_files = 'SubstrateSdk/Classes/**/*'
  s.dependency 'IrohaCrypto/sr25519', '~> 0.9.0'
  s.dependency 'IrohaCrypto/ed25519', '~> 0.9.0'
  s.dependency 'IrohaCrypto/secp256k1', '~> 0.9.0'
  s.dependency 'IrohaCrypto/Scrypt', '~> 0.9.0'
  s.dependency 'IrohaCrypto/ss58', '~> 0.9.0'
  s.dependency 'ReachabilitySwift', '~> 5.0'
  s.dependency 'RobinHood', '~> 2.6.0'
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
