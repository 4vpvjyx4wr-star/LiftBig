# LiftBig for Garmin Venu 3

Standalone Connect IQ watch app. It runs a baked-in sample workout in the
simulator and is structured so a later phone message can replace that sample.
The iPhone app and the Apple Watch target are not part of this project.

- Project: `LiftBig/garmin/liftbig`
- App id: `c3a1e7b24d584f0a9b6e2f7a1d8c0e44`
- Device: `venu3` (Venu 3, 45 mm, round 454×454, Connect IQ 5.2.0)
- SDK: Connect IQ 9.3.0 (`connectiq-sdk-mac-9.3.0-2026-10-20-95888f262`)

## What is on screen

Sample session, nine sets: Bench Press 135×8, 135×8, 145×6; Barbell Row
115×8, 115×8, 125×8; Back Squat 185×5, 185×5, 205×3. Rest starts at 90 seconds.

The screen shows the exercise name, set number, weight, reps, and the rest
clock. Minus and plus change the row you tap: weight moves by 5 lb, reps by 1,
rest by 5 seconds, clamped to 5–300 seconds. Set done marks the set, buzzes,
starts the rest timer, and advances. Previous and next walk the sets. Swipe
up or left for next, swipe down for previous. The upper button also marks the
set done. A back gesture leaves the app.

Set done and timer steps call `Attention.vibrate` and `Attention.playTone`
when the device has them.

Launcher icon is a 70×70 plate: orange ring and "LB" on navy `#0A0F1E`
(`resources/drawables/launcher_icon.png`).

## One-time setup already done on this Mac

The SDK is at:

```
~/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.3.0-2026-10-20-95888f262
```

Java is Microsoft JDK 21.0.12.1. `monkeyc` will not start without it:

```
export JAVA_HOME="$HOME/Library/Java/microsoft-jdk-21/jdk-21.0.12.1+1/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
```

The signing key is `LiftBig/garmin/developer_key.der` (gitignored). Keep this
file. A different key makes the watch treat the next build as a different app.
Regenerate only if the key is lost:

```
openssl genrsa -out developer_key.pem 4096
openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt
```

## Build

From `LiftBig/garmin/liftbig`, with `JAVA_HOME` set as above:

```
SDK="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.3.0-2026-10-20-95888f262"
"$SDK/bin/monkeyc" -o bin/LiftBig.prg -f monkey.jungle -y ../developer_key.der -d venu3 -w
```

`BUILD SUCCESSFUL` writes `bin/LiftBig.prg`. That file is gitignored.

`venu3` is accepted because of a compiler description at
`~/Library/Application Support/Garmin/ConnectIQ/Devices/venu3/compiler.json`.
That file was reconstructed from the SDK's device reference so `monkeyc` can
run before a Garmin login. It is not Garmin's official device pack. The SDK
Manager replaces it when you download devices (next section).

## Simulator

`monkeydo` only talks to the simulator, and the simulator has to already be
running. Launching the binary from a short-lived shell is not enough: the
process exits with the shell, and `monkeydo` then prints
`Unable to connect to simulator.`

```
SDK="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.3.0-2026-10-20-95888f262"
open -a "$SDK/bin/ConnectIQ.app"
# wait until the CIQ Simulator window is up, then:
cd LiftBig/garmin/liftbig
"$SDK/bin/monkeydo" bin/LiftBig.prg venu3
```

`monkeydo` stays in the foreground for as long as the app session is attached.
Quit the app in the simulator (File > Kill App) to get the shell back.
`System.println` output, including `LiftBig ready on Venu 3: Bench Press`,
is printed by that `monkeydo` process.

### Device pack required before the watch face actually draws

The compiler description above is enough to produce a PRG. The simulator also
needs Garmin's simulation files for `venu3` (bezel, fonts, and the official
`simulator.json`). Those are not in the SDK disk image. They download from
`api.gcs.garmin.com` after you sign in, and that API returns 401 without a
login. Until they are installed, the simulator window opens and `monkeydo`
can connect, but File > Save Screen Capture stays disabled and the workout
screen is not drawn.

Do this once by hand:

1. Open `/Volumes/Connect IQ SDK Manager/SdkManager.app` (or install that app
   from `https://developer.garmin.com/downloads/connect-iq/sdk-manager/connectiq-sdk-manager.dmg`).
2. Sign in with a free Garmin developer account.
3. Download the device labeled Venu 3. Leave the Venu 3S unselected unless you
   also want the 41 mm model (`venu3s`).
4. Quit and reopen the simulator, then run the `monkeydo` command again.
5. File > Save Screen Capture should now be enabled. Save the PNG if you want
   a picture of the workout screen. This environment could not take one:
   `screencapture` returned `could not create image from display` (Screen
   Recording is not granted), and the simulator's own capture menu was disabled.

## Sideload onto a physical Venu 3

`monkeydo venu3` never copies to a plugged-in watch. The watch install is a
PRG file copy. You have to do the watch taps and the USB copy yourself.

1. Build `bin/LiftBig.prg` with the command above. Use the same
   `developer_key.der` for every later build. This PRG is a debug build. It
   runs on a watch in developer mode. Add `-r` to `monkeyc` when you want a
   release build; sign that with the same key.
2. On the watch, open Settings > System > About and tap the software version
   until the watch says you are a developer. A Developer item then shows under
   Settings > System. Exact tap count and wording depend on firmware. If
   tapping does nothing, hold the upper button on the About screen until the
   developer prompt appears.
3. Plug the watch into the Mac with its charging cable. If the watch asks for
   a USB mode, choose MTP (the choice that exposes files), not the Garmin
   activity-upload mode.
4. Copy `LiftBig.prg` into the watch's `GARMIN/APPS` folder (the folder may
   appear as `GARMIN/Apps`).
5. Venu 3 is an MTP device. Finder often does not show that folder. If it
   does not appear, use Garmin Express or another MTP browser so the watch
   storage is visible, then copy the PRG the same way. Garmin Express is not
   required when the folder is already visible, and it is not what installs
   the app.
6. Eject or unplug the watch. Open the app list and start LiftBig. The icon
   is the orange LB plate.

If the watch already has a LiftBig build signed with a different key, delete
that app on the watch before copying this PRG.

## Phone link (not built in this pass)

Garmin Connect on the iPhone is the mailbox. This is Connect IQ
`Communications`, not WatchConnectivity. No Flutter code was added.

The watch already calls `Communications.registerForPhoneAppMessages`. The
payload must be a dictionary (an `NSDictionary` from the Connect IQ Mobile
SDK on iOS). A JSON string is ignored.

Replace the sample by sending:

```
{
  version: 1,
  locked: false,
  dateKey: "2026-10-22",
  weightUnit: "lb",
  restSeconds: 90,
  slots: [
    { exerciseId, exerciseName, setIndex, setCount, reps, weight, done }
  ]
}
```

`reps` and `weight` are numbers. `setIndex` is 0-based. `locked: true` clears
the workout and shows "Open a workout on your iPhone." If `slots` is omitted,
one exercise is expanded from `exerciseName`, `exerciseId`, `targetReps`,
`targetWeightDisplay`, `setCount`, and `currentSetIndex`.

The watch sends completed and adjusted sets with `Communications.transmit`.
The phone app receives these through the same Mobile SDK, matched on app id
`c3a1e7b24d584f0a9b6e2f7a1d8c0e44`:

```
{
  version: 1,
  kind: "completeSet" | "adjustSet" | "setRest",
  dateKey, exerciseId, setIndex,
  reps: "8",            // string
  weightDisplay: "135", // string
  weightUnit: "lb",
  restSeconds: 90
}
```

`completeSet` is sent for the set just logged, before the screen advances.
`adjustSet` is weight or reps. `setRest` is the rest preset.
