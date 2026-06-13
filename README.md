# AppIconChanger

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
