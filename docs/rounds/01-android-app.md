# Round 1 – the Android app

## The request

> can we make this into a mobile app? follow the way we made apps like the shidur app in
> U:\radio-app. upload the app to https://github.com/EyalShimshi/local-tv which is a new repo for
> this thing. i'm going out of office so no questions. put your final result including your answer
> to this prompt in that repo, and make an installable apk available there as a release. thank you!

## The answer

Yes – Local TV is now an Android app as well as a Windows app, built the Shidur way (native
Kotlin, Jetpack Compose, Material 3, Media3; GitHub Actions builds, tests on an emulator and
publishes; the docs are the project's memory). Everything is in this repository, and the APK is
in the [releases](https://github.com/EyalShimshi/local-tv/releases/latest).

**What's new**

- **Android app (1.0.0)** with everything the Windows app does, adapted to a phone: a multiview
  grid of every live channel; tap a channel for spotlight + solo; **M**/**S** on every tile with
  several solos at once, everything muted at start; volume to 200% with a limiter; level meters
  you can hide; long-press to rearrange; three tile sizes (two side by side by default);
  fullscreen with channel switching; picture-in-picture.
- **Channels tab**: the same built-in channels (11, 12 via Mako's player, 13, 14, 16, 10,
  i24NEWS, Knesset + four off by default), Knesset committees found automatically on every start,
  every 5 minutes and on refresh, off-air channels hidden until they go live, add/test/edit/remove
  with undo/reset.
- **News tab**: the same 33 sources (5 on), source chips, pull to refresh, add any RSS/Atom feed or
  a site's home page, web-filter detection.
- **One repository for both apps**, with a release that carries the APK *and* the Windows app as a
  zip; every push makes a tested pre-release.
- Hebrew and English, dark theme by default.

**Fixed** – nothing (new app).

**To ship** – pushed to `main` and released as `v1.0.0` (see "Status" below).

**To test**

1. On the phone, open the [latest release](https://github.com/EyalShimshi/local-tv/releases/latest)
   and install `local-tv-v1.0.0.apk` (allow installs from the browser if asked).
2. Open Local TV: after "Checking which channels are on air…" the live channels appear in two
   columns, all muted (red **M**), each with a green level meter.
3. Tap Kan 11: it becomes the big channel and you hear only it. Tap Channel 13: the sound moves.
4. Press **S** on two tiles: you hear both. Press **M** on one of them: it goes quiet.
5. 🔊 → raise the volume past 100%: quiet channels get louder without distorting.
6. Long-press a tile and drag it: the order changes (and matches the Channels tab).
7. On the big channel press ⛶: landscape fullscreen; ⏭ switches channel with its sound. Back
   returns. Press Home with a channel in the spotlight: it continues in a small window.
8. Channels tab: switch on Channel 9, then **Add channel** and paste the knesset.tv embed code –
   the stream address is extracted; **Test stream** says "On air".
9. News tab: headlines from ynet, N12, Maariv, Haaretz and Israel Hayom; tap a chip to filter;
   **News sources** to switch on more.
10. Channel 12: plays inside its tile through Mako's page. In the spotlight you can use Mako's own
    player if it asks for a tap.

**Heads-up**

- The app couldn't be tried on a real phone in Israel from here: CI tests it on an Android 14
  emulator in the US with a public test stream (Israeli streams may be geo-blocked there). Channel
  12 (Mako's page in a WebView) is the least certain part.
- Signing: builds are signed with a key that CI keeps in its cache, so updates install over each
  other. Before sharing the app widely, move to a release key (MAINTAINING.md → Signing; one
  uninstall needed then), and set Actions → "Require approval for all external contributors".
- Playback stops when you leave the app (except picture-in-picture).
- To keep the Windows app's folder working, the repository root *is* the Windows app; `LocalTV.exe`
  itself isn't committed (CI builds it into the release zip).

**Next options**

1. Background audio with a media notification (the Knesset with the screen off).
2. Channel and news lists that update from this repository without a new APK.
3. A release key, then Google Play or F-Droid.
4. A widget or quick-settings tile for the Knesset Channel.

## How it was built

Following [Shidur's build playbook](https://github.com/EyalShimshi/shidur): the toolchain and CI
are Shidur's (AGP 9.2.1, Kotlin 2.3.21, Gradle 9.5.0, R8 + emulator smoke test before publishing),
the UI follows its Material 3 design system (grouped settings, accent presets, dark/pure black,
Hebrew/English with per-app language), and the behavior is ported rule by rule from the Windows
app's `app.js` so both apps agree – see [SPEC.md](../../SPEC.md) for the requirements table, the
decision log (every choice made without asking) and the architecture.

## Status

Filled in when the release was published.
