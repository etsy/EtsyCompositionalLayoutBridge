# EtsyCompositionalLayoutBridge

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/EtsyCompositionalLayoutBridge.svg?style=flat)](https://cocoapods.org/pods/EtsyCompositionalLayoutBridge)
[![License](https://img.shields.io/cocoapods/l/EtsyCompositionalLayoutBridge.svg?style=flat)](https://cocoapods.org/pods/EtsyCompositionalLayoutBridge)
[![Platform](https://img.shields.io/cocoapods/p/EtsyCompositionalLayoutBridge.svg?style=flat)](https://cocoapods.org/pods/EtsyCompositionalLayoutBridge)

`EtsyCompositionalLayoutBridge` allows you to intermix  `UICollectionViewCompositionalLayout` and `UICollectionViewFlowLayout`! 

It's perfect if you want to introduce `UICollectionViewCompositionalLayout` into your existing `UICollectionViewFlowLayout` based `UICollectionView` without having to rewrite _everything_. Being able to mix concepts between the two collection view layout paradigms allows you to leverage both the simplistic ('it just works') `UICollectionViewFlowLayout` and the complex yet flexible `UICollectionViewCompositionalLayout` simultaneously. This allows for brand new possibilities on `UICollectionView`! 

For any given `UICollectionView` section's header, footer or items: you can choose to use either a `UICollectionViewCompositionalLayout` or `UICollectionViewFlowLayout` based layout. `EtsyCompositionalLayoutBridge` uses a `UICollectionViewCompositionalLayout` at its core allowing you to leverage all the layout has to offer, such as custom supplementary items and more!

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

1. Create an `EtsyCompositionalLayoutBridge` instance using the initializer 
    `EtsyCompositionalLayoutBridge(collectionView:flowLayout:delegate:dataSource:flowLayoutDelegate:)`.

2. Implement the `EtsyCompositionalLayoutBridgeDelegate` protocol on `delegate` passed into the initializer above.
    
    * The `EtsyCompositionalLayoutBridgeDelegate.compositionalLayoutBridge(_:shouldUseFlowLayoutFor:)`
    delegate method allows you to return a `Bool` that determines whether or not the bridge will use `UICollectionViewFlowLayout`  behavior for a specific section of the collection view.
    
    * The `EtsyCompositionalLayoutBridgeDelegate.compositionalLayoutBridge(_:layoutSectionFor:environment:)`
    delegate method allows you to provide an `NSCollectionLayoutSection` for sections in the collection view you returned `false` for in the `compositionalLayoutBridge(_:shouldUseFlowLayoutFor:)` delegate method.
    
3. Set  `collectionView.collectionViewLayout` to `.layout()` on the `EtsyCompositionalLayoutBridge` instance you created in step 1.


### Example
The provided demo app contains an example of `EtsyCompositionalLayoutBridge` in action, please see: `Example/EtsyCompositionalLayoutBridge/DemoViewController.swift`. In the example, we also show you how you can mix and match `UICollectionViewFlowLayout` and `UICollectionViewCompositionalLayout`.

<details>
<summary>Screenshot</summary>
<p>

![image](https://user-images.githubusercontent.com/18605871/121741214-21a29200-caf6-11eb-9094-0d4196f1366b.png)

</p>
</details>
