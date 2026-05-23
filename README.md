# expo-dev-launcher cycle repro

Minimal reproduction for the iOS archive build cycle introduced by
[expo/expo#46125](https://github.com/expo/expo/pull/46125) (released in
`expo-dev-launcher@56.0.15`).

## What this demonstrates

When all three of the following stack in a single Expo SDK 56 iOS app, an
archive build fails with `error: Cycle inside <target>; building could produce
unreliable results.`:

1. `expo-dev-launcher@56.0.15` (transitive dependency of `expo-dev-client`).
   The `withStripLocalNetworkKeysForRelease` config plugin is applied even
   though `expo-dev-client` is **not** listed in `app.json` `plugins`
   (autolinking + the chained plugin call still injects the Run Script phase
   into the main iOS target).
2. An embedded app extension target (here, a minimal WidgetKit widget added
   via `@bacons/apple-targets`).
3. Any additional Run Script phase that participates in the same dependency
   graph (here, `@sentry/react-native`'s "Upload Debug Symbols to Sentry").

## How to reproduce

```bash
git clone https://github.com/zhxycn/expo-dev-launcher-cycle-repro
cd expo-dev-launcher-cycle-repro
bun install      # or npm/pnpm/yarn install
eas build -p ios --profile production
```

The build fails at the archive step with the cycle path:

```
→ Embed DummyWidget.appex
○ depends on script phase "Upload Debug Symbols to Sentry"
○ depends on script phase "[Expo Dev Launcher] Strip Local Network Keys for Release"
○ depends on ProcessInfoPlistFile (App.app/Info.plist)
○ depends on Embed DummyWidget.appex     ← cycle
```

## Why it fails

`#46125` added `inputPaths: ['"$(TARGET_BUILD_DIR)/$(INFOPLIST_PATH)"']` to
the strip script but no matching `outputPaths`, putting the script downstream
of `ProcessInfoPlistFile` in Xcode's dependency graph. During archive, the
final `App.app/Info.plist` is materialized **after** `Embed App Extensions`
because Xcode finalizes Info.plist post-extension-embedding. Combined with
Sentry's symbol-upload phase (which also has Info.plist as a transitive
dependency), the result is a four-edge cycle.

## Notes

- Reproduces on EAS Build (default `macos-tahoe-26-xcode-26.4` image) and
  locally with `eas build -p ios --local`.
- Reverting `expo-dev-launcher` to `56.0.12` (or earlier) makes the build
  succeed.
- Removing `@sentry/react-native` while keeping the extension does not
  necessarily make the cycle disappear — any phase that brings Info.plist
  into the dependency chain between Strip and Embed will close the loop.
