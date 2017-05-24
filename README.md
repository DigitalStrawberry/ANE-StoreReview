# ANE-StoreReview

Adobe AIR native extension for requesting app reviews with the new [StoreKit API](https://developer.apple.com/app-store/ratings-and-reviews/) introduced in iOS 10.3.

### Getting Started

Download the ANE from the [bin](bin/) directory or from the [releases](../../releases/) page and add it to your app's descriptor:

```xml
<extensions>
    <extensionID>com.digitalstrawberry.ane.storeReview</extensionID>
</extensions>
```

When packaging your app for iOS, you need to point to a directory with iOS 10.3 SDK (available in Xcode 8.3) using the `-platformsdk` option in `adt` or via corresponding UI of your IDE:

```
-platformsdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS10.3.sdk
```

### Usage

The native API is only available in iOS 10.3 or newer. Use the `isSupported` getter to find out if the current device supports this API:

```as3
if(StoreReview.isSupported)
{
    // Use the rest of the API
}
```

To prompt the user for a review, use the `requestReview` method. Read the [official guidelines document](https://developer.apple.com/ios/human-interface-guidelines/interaction/ratings-and-reviews/) to learn when the method should be used.

```as3
StoreReview.requestReview();
```

> Although you should call this method when it makes sense in the user experience flow of your app, the actual display of the review dialog is governed by App Store policy. Because this method may or may not present an alert, it's not appropriate to call it in response to a button tap or other user action.
>
> When you call this method while your app is still in development mode, the review dialog is always displayed so that you can test the user interface and experience. However, this method has no effect when you call it in an app that you distribute using TestFlight.

The system automatically limits the display of the prompt to three occurrences per app within a 365-day period. The extension keeps track of the current app environment (development, TestFlight, App Store) and the number of requests made in the last 365 days to make a best guess on whether the review dialog will display or not. The `willDialogDisplay` getter returns `true` if:

  1. Less than 3 requests have been made in the last 365 days, or
  2. The app is in development (i.e. deployed directly to a device).

TestFlight builds always return `false`. Note the user may have already left a review or disabled the rating prompts for all apps in the device settings. This information is not exposed via public API, thus the returned value may not be correct in all situations.

```as3
if(StoreReview.willDialogDisplay)
{
    // The dialog will likely be displayed after this request
    StoreReview.requestReview();
}
```

You can also query the number of requests made in the last 365 days as well as the number of days that have passed since the last request:

```as3
trace(StoreReview.numRequestsIn365Days);

trace(StoreReview.daysSinceLastRequest); // -1 if no requests have been made yet
```

You can check the last app version for which a review request was made using the `lastRequestedReviewVersion` getter. The `currentVersion` getter returns the current app version:

```as3
// The current app version is different from the last time we made a review request
if(StoreReview.lastRequestedReviewVersion != StoreReview.currentVersion)
{
    StoreReview.requestReview();
}
```

### Changelog

#### May 24, 2017 (v1.1.0)

* Added `lastRequestedReviewVersion` and `currentVersion` getters

#### May 23, 2017 (v1.0.0)

* Public release
