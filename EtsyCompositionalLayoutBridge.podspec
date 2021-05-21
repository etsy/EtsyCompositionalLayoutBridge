#
# Be sure to run `pod lib lint EtsyCompositionalLayoutBridge.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'EtsyCompositionalLayoutBridge'
  s.version          = '1.0.0'
  s.summary          = 'Allows for mixing collection view flow layout with compositional layout.'
  s.description      = "Intermix concepts from UICollectionViewCompositionalLayout and UICollectionViewFlowLayout. Perfect for if you want to introduce UICollectionViewCompositionalLayout into your existing UICollectionViewFlowLayout based UICollectionView while not having to rewrite everything."
  s.homepage         = 'https://github.com/etsy/EtsyCompositionalLayoutBridge'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.authors          = 'Etsy'
  s.source           = { :git => 'https://github.com/etsy/EtsyCompositionalLayoutBridge.git', :tag => s.version.to_s }
  s.swift_version    = '5.0'
  s.ios.framework    = 'UIKit'
  s.ios.deployment_target = '13.0'

  s.source_files = 'Sources/EtsyCompositionalLayoutBridge/Classes/**/*'

end
