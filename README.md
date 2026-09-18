# Offline Music

Lightweight Swift/UIKit offline music player for iPhone 5s and iOS 12.0+. It imports MP3, M4A, AAC, and WAV files into Documents, supports background audio, lock-screen controls, shuffle/repeat, and a persistent library.

## Windows build and install

1. Create a GitHub repository and push this folder, preserving `.github/workflows/build-ios.yml`.
2. Open the repository's **Actions** tab, run **Build unsigned iOS app**, and wait for it to finish.
3. Open the completed workflow run and download the `OfflineMusic-unsigned-ipa` artifact. Extract `OfflineMusic-unsigned.ipa`.
4. Install Sideloadly on Windows, connect the iPhone 5s, select the IPA, sign in with an Apple ID, and start sideloading.
5. On iOS 12, trust the developer profile in Settings > General > Profiles & Device Management if prompted. Unsigned builds require Sideloadly's signing process; the workflow itself only packages the unsigned IPA.

The GitHub runner performs the actual iOS build. No absolute local paths are used.
