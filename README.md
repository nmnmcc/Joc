# Joc

## Just simply lock your Mac

Joc is a small SwiftUI companion that locks a Mac from an iPhone, Apple
Watch, or Control Center. The companion devices write one CloudKit command;
the macOS menu bar agent polls that command, locks the local screen, and
publishes the result.

[![CI](https://github.com/nmnmcc/Joc/actions/workflows/ci.yml/badge.svg)](https://github.com/nmnmcc/Joc/actions/workflows/ci.yml)
[![License: GPL-2.0-only](https://img.shields.io/badge/License-GPL--2.0--only-blue.svg)](LICENSE)

> Joc is an early-stage personal and internal tool. The macOS target uses a
> private Apple API and is not currently suitable for Mac App Store
> distribution.

## Features

- Lock the connected Mac from an iPhone app, Apple Watch app, or Control
  Center control.
- Show the Mac's latest state on the companion devices and in the menu bar.
- Use a single CloudKit record for the current request and a single record for
  the latest result.
- Avoid sending passwords, screen contents, or other files through CloudKit.

## Targets

| Target | Platform | Role |
| --- | --- | --- |
| `Joc` | iOS | Companion app |
| `JocControl` | iOS 18 | Control Center control |
| `JocWatch` | watchOS | Companion app |
| `JocWatchControl` | watchOS 26 | watchOS control |
| `JocMac` | macOS | Menu bar agent and local screen lock |

The repository and public product name are Joc. The generated Xcode target
names, bundle identifiers, and CloudKit identifiers all use Joc. Configure
the App IDs and container listed below before building; data in another
CloudKit container is not migrated automatically.

## Requirements

- macOS 14 or later
- Xcode 26 or later
- An Apple Developer account with iCloud/CloudKit enabled
- Nix, Devenv, and Direnv for the scripted development environment

## Build locally

```sh
git clone https://github.com/nmnmcc/Joc.git
cd Joc
direnv allow
generate
format
lint
build
open Joc.xcodeproj
```

The generated project is checked in for convenience. `project.yml` is the
source of truth; run `generate` after changing it. The build script compiles
the iOS app for a simulator without code signing. Device builds require your
own development team and provisioning configuration.

## CloudKit setup

Every target must have iCloud/CloudKit enabled in Apple Developer and must
use the same iCloud account during development.

1. Register the container `iCloud.cc.nmnm.joc` and associate it with the
   app IDs `cc.nmnm.joc`, `cc.nmnm.joc.control`,
   `cc.nmnm.joc.watchkitapp`, and
   `cc.nmnm.joc.watchkitapp.control`.
2. In the CloudKit Dashboard Development environment, create the private
   database record type `LockCommand` with these fields:
   `commandID` (String), `action` (String), `createdAt` (Date), and
   `source` (String). Joc always uses the record name `current`, so no
   query index is needed for `createdAt`.
3. Create `LockStatus` with `state` (String), `updatedAt` (Date),
   `message` (String), `processedCommandID` (String), and `hostName`
   (String).
4. Deploy the schema to Production before distributing a TestFlight or
   release build. Keep the Mac menu bar agent running while testing.

When creating a fork, replace the bundle identifiers, CloudKit container, and
entitlements with identifiers owned by your Apple Developer team. Do not
commit provisioning profiles, certificates, or private keys.

## Privacy and platform limitations

CloudKit carries only the lock request and the latest status. The Mac stores
the last processed command ID in local `UserDefaults` to avoid executing the
same request twice.

`Sources/Shared/ScreenLock.swift` dynamically loads
`login.framework` and calls `SACLockScreenImmediate`, a private macOS API.
This implementation is intended for personal signing and internal tools.
Use an Apple-supported locking mechanism before considering distribution
through the Mac App Store, and review the platform policies for your use case.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the development workflow and
[SECURITY.md](SECURITY.md) for private vulnerability reports. Please avoid
including personal CloudKit data in issues and pull requests.

## License

Joc is distributed under the **GNU General Public License, version 2 only**.
See [LICENSE](LICENSE) for the complete terms.
