![Latest Crystallized thought](https://www.maxprudhomme.com/api/crystallized.svg)

Crystallized is a tiny macOS menu bar app that periodically generates reflective thoughts and can send them to a webhook.

## Compile And Run

Requirements:

- macOS
- Xcode installed

Build the app:

```sh
xcodebuild \
  -project crystallized.xcodeproj \
  -scheme crystallized \
  -configuration Release \
  -derivedDataPath .DerivedData \
  build
```

Run it:

```sh
open .DerivedData/Build/Products/Release/crystallized.app
```

Crystallized runs as a menu bar app, so look for its icon in the macOS menu bar rather than the Dock. It supports a POST endpoint with a SecretKey send along when added to securize the endpoint.
