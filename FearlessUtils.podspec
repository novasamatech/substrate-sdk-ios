#
# Be sure to run `pod lib lint FearlessUtils.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FearlessUtils'
  s.version          = '0.6.0'
  s.summary          = 'Utility library that implements clients specific logic to interact with substrate based networks'

  s.homepage         = 'https://github.com/soramitsu/fearless-utils-iOS'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ERussel' => 'rezin@soramitsu.co.jp' }
  s.source           = { :git => 'https://github.com/soramitsu/fearless-utils-iOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'

  s.source_files = 'FearlessUtils/Classes/**/*'
  s.dependency 'IrohaCrypto/sr25519', '~> 0.7.0'
  s.dependency 'IrohaCrypto/ed25519', '~> 0.7.0'
  s.dependency 'IrohaCrypto/secp256k1', '~> 0.7.0'
  s.dependency 'IrohaCrypto/Scrypt', '~> 0.7.0'
  s.dependency 'TweetNacl', '~> 1.0.0'
  s.dependency 'BigInt', '~> 5.0'
  s.dependency 'xxHash-Swift', '~> 1.0.0'
  
  s.test_spec do |ts|
      ts.source_files = 'Tests/**/*.swift'
      ts.resources = ['Tests/**/*.json']
  end
end
