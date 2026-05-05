# Helium

Minimal iOS/iPadOS WebKit browser inspired by Helium's low-bloat browsing posture.

## What is included

- Native SwiftUI shell around `WKWebView`
- In-memory tabs with regular and private browsing
- URL/search normalization with DuckDuckGo search
- Bookmarks, history, and settings persisted locally as JSON
- Bundled WebKit content-rule-list adblocker
- Share sheet and basic page security indicator

## Preview

Xcode is enough for simulator preview:

```sh
open Helium.xcodeproj
```

Select an iPhone or iPad simulator and run the `Helium` scheme.

For Web Inspector, enable Safari's Develop menu on macOS. Debug builds mark the app's `WKWebView` instances inspectable.
