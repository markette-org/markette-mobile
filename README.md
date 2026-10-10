# markette-mobile

Markette for **Android** and **iOS**: the [Markette web app](https://github.com/markette-org/markette-web)
in [Capacitor 8](https://capacitorjs.com), plus **“Share with Markette”**. Share a link, some text or
photos/videos from any app and Markette opens a draft with them, ready to tailor and schedule.

On first launch the app asks for your Markette server URL. Sign in with your password, or with a
personal API token (useful with single sign-on).

## Build

Clone this repository next to `markette-web`:

```bash
git clone https://github.com/markette-org/markette-web.git
git clone https://github.com/markette-org/markette-mobile.git && cd markette-mobile
npm ci
npm run sync            # builds ../markette-web into www/ and syncs both native projects
```

`WEB_DIR=/path/to/markette-web` overrides where the web app is taken from.

### Android

```bash
npm run android:debug   # android/app/build/outputs/apk/debug/app-debug.apk
```

This needs JDK 21 and Android SDK 36, or use the Docker image in `Dockerfile.android`:

```bash
docker build -t markette-android-build -f Dockerfile.android .
docker run --rm -v "$PWD":/app markette-android-build ./gradlew assembleDebug
```

For a release build, create a keystore and an `android/keystore.properties` (never committed), then
`npm run android:release`. The app id is `app.markette.mobile`.

### iOS (macOS with Xcode 16+)

```bash
npm run sync
open ios/App/App.xcodeproj
```

The project already contains the **ShareExtension** target, embedded in the app. Before the first build:

1. Select your team for both the *App* and *ShareExtension* targets (Signing & Capabilities).
2. Change the bundle ids if `app.markette.mobile` is not available to your team, and keep
   `…​.ShareExtension` as the extension's suffix.
3. Create the App Group `group.app.markette.mobile` (or your own: then update `capacitor.config.ts`,
   `ShareExtension/ShareViewController.swift` and both `.entitlements` files) and enable it on both targets.

The Share Extension copies shared files into the App Group, stores the share for
[`@capgo/capacitor-share-target`](https://github.com/Cap-go/capacitor-share-target) and opens the app
through the `markette://` URL scheme.

`Info.plist` allows plain-http servers (`NSAllowsArbitraryLoads`) for test installs. Remove that before
publishing to the App Store and use an HTTPS server.

### Icons and splash

The sources are in `assets/`. Regenerate with `npm run assets`.

## Limitations

- Single sign-on and OAuth channel connections finish in the system browser, because the identity
  providers redirect to the web app. Use API-token sign-in in the app; connect OAuth channels from the web.
- iOS only allows a share extension to open its app through a workaround. If it doesn't open, switch
  to Markette: the share is picked up when the app becomes active.

## License

[AGPL-3.0-only](LICENSE).
