# AppIconChanger

![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=flat-square&logo=swift&logoColor=white)
![SPM](https://img.shields.io/badge/SPM-compatible-orange?style=flat-square)
![Platform](https://img.shields.io/badge/iOS-v13.0-yellow?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-black?style=flat-square)

A small Swift package for switching iOS alternate app icons from SwiftUI-friendly state.

## Usage

Define the icons listed in your app's `CFBundleAlternateIcons`:

```swift
import AppIconChanger

enum AppIcon: String, CaseIterable, Identifiable, AppIconRepresentable {
  case primary
  case dark

  var id: String { rawValue }

  var iconName: String? {
    switch self {
    case .primary:
      nil
    case .dark:
      "DarkIcon"
    }
  }

  var displayName: String {
    switch self {
    case .primary:
      "Primary"
    case .dark:
      "Dark"
    }
  }
}
```

Use `AppIconChanger` as a main-actor observable object:

```swift
@StateObject private var iconChanger = AppIconChanger<AppIcon>()

Task {
  try await iconChanger.setIcon(to: .dark)
}
```

The package also keeps `changeIcon(to:)` as a fire-and-forget convenience method for simple UI actions.

## SwiftUI integration

First, register alternate icons in your app target's `Info.plist`:

```xml
<key>CFBundleIcons</key>
<dict>
  <key>CFBundleAlternateIcons</key>
  <dict>
    <key>DarkIcon</key>
    <dict>
      <key>CFBundleIconFiles</key>
      <array>
        <string>DarkIcon</string>
      </array>
    </dict>
  </dict>
</dict>
```

Then connect `AppIconChanger` to a SwiftUI picker or list:

```swift
import AppIconChanger
import SwiftUI

struct IconSettingsView: View {
  @StateObject private var iconChanger = AppIconChanger<AppIcon>()

  var body: some View {
    List(AppIcon.allCases) { icon in
      Button {
        iconChanger.changeIcon(to: icon)
      } label: {
        HStack {
          Text(icon.displayName)

          Spacer()

          if iconChanger.currentIconName == icon.iconName {
            Image(systemName: "checkmark")
          }
        }
      }
      .disabled(!iconChanger.supportsAlternateIcons)
    }
  }
}
```

Use the throwing API when the calling screen needs to show its own error state:

```swift
Button("Use Dark Icon") {
  Task {
    do {
      try await iconChanger.setIcon(to: .dark)
    } catch {
      // Present an alert, toast, or other app-specific error UI.
    }
  }
}
```
