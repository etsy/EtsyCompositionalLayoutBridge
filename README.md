# EtsyCompositionalLayoutBridge

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/EtsyCompositionalLayoutBridge.svg?style=flat)](https://cocoapods.org/pods/EtsyCompositionalLayoutBridge)
[![License](https://img.shields.io/cocoapods/l/EtsyCompositionalLayoutBridge.svg?style=flat)](https://cocoapods.org/pods/EtsyCompositionalLayoutBridge)
[![Platform](https://img.shields.io/cocoapods/p/EtsyCompositionalLayoutBridge.svg?style=flat)](https://cocoapods.org/pods/EtsyCompositionalLayoutBridge)


Intermix concepts from `UICollectionViewCompositionalLayout` and `UICollectionViewFlowLayout`. Perfect if you want to introduce `UICollectionViewCompositionalLayout` into your existing `UICollectionViewFlowLayout` based `UICollectionView` while not having to rewrite _everything_.

## Requirements

Xcode 11+, iOS 13+. 

## Installation

### Cocoapods

EtsyCompositionalLayoutBridge is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'EtsyCompositionalLayoutBridge', '~> 1.0'
```

### Carthage
Add the following to your Cartfile:
```
github "etsy/EtsyCompositionalLayoutBridge" ~> 1.0
```
If you use Carthage to build your dependencies, make sure you have added `EtsyCompositionalLayoutBridge.framework` to "Linked Frameworks and Libraries" of the appropriate target and include the framework in the Carthage framework copying building phase. Note: if you have an M1 powered Mac, please note that you may have issues using Carthage as a dependency manager.   

### Swift Package Manager

1. In Xcode, navigate to File -> Swift Packages -> Add Package Dependency
2. Paste the repository URL (https://www.github.com/etsy/EtsyCompositionalLayoutBridge), press next.
3. Under 'Rules', select 'Branch' and set to 'main'.
4. Click Finish

## Usage

1. Create an `EtsyCompositionalLayoutBridge` instance via the initializer 
    `EtsyCompositionalLayoutBridge(collectionView:flowLayout:delegate:dataSource:flowLayoutDelegate:)`.

2. Implement the `EtsyCompositionalLayoutBridgeDelegate` protocol on the `delegate` from the initializer above.
    
    * `EtsyCompositionalLayoutBridgeDelegate.compositionalLayoutBridge(_:shouldUseFlowLayoutFor:)`
    delegate method allows you to specify a `Bool` that determines whether or not you want `UICollectionViewFlowLayout`  behavior for a specific section of the collection view.
    
    * `EtsyCompositionalLayoutBridgeDelegate.compositionalLayoutBridge(_:layoutSectionFor:environment:)`
    delegate method allows you to provide an `NSCollectionLayoutSection` for sections in the collection view you returned `true` for in the `compositionalLayoutBridge(_:shouldUseFlowLayoutFor:)`
    
3. Set the `collectionView.collectionViewLayout` to `.layout()` on the instance you created in step 1.


#### Mixing and matching `UICollectionViewFlowLayout` and `UICollectionViewCompositionalLayout`
Being able to mix concepts between the two collection view layout paradigms allows you to leverage the simplistic ('it just works') `UICollectionViewFlowLayout` and the complex yet flexible `UICollectionViewCompositionalLayout`. The demo app contains an example of this, in particular please see: `Example/EtsyCompositionalLayoutBridge/DemoViewController.swift`.


## License

TBD
