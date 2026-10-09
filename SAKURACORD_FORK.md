# SakuraCord Sparkle fork

This fork tracks Sparkle 2.10.0 and keeps its standard signed-feed, archive,
bundle-identity, and installation verification.

## Explicit build selection

Version `2.9.6-sakuracord.3` adds the main-thread API
`try updater.checkForUpdates(forVersion: bundleVersion)`. Call it only after the
user explicitly selects a build, with the updater configured for that build's
signed appcast. Start the updater first. The API refuses a busy updater,
a downloaded resumable update, or an already running installer.

The selected build can have an older, equal, or newer `CFBundleVersion`.
Sparkle still shows its normal manual update prompt and verifies the download
and installed bundle. Selection requires a successfully verified signed feed;
the signed-feed recovery fallback cannot authorize replacement. Exactly one
compatible full application archive with an EdDSA signature must match the
requested version. Platform, hardware, minimum-update-version, and channel
restrictions still apply. Delta and package installation are not eligible.

The driver snapshots authorization for this one check. Only the selected item
carries it into the existing secure installer connection. For explicit replacement,
the installer authenticates the request's XPC audit token against the installed
host's designated code requirement and executable path, including the cdhash for
ad-hoc signatures. Missing identity information fails closed. External updater
processes and the optional installer-connection forwarding service cannot use
this API; the installed host must connect directly. The installer requires
the extracted bundle's version to exactly match the authorized version, including
when the new version would otherwise be an upgrade. Authorization is never read
from appcast properties, the downloaded application's Info.plist, or preferences,
and is not serialized with cached appcast items. Aborting a check discards any
downloaded explicit selection rather than retaining it for later checks. Automatic checks keep their
normal version ordering.

## Existing release-track compatibility

The Boolean `SUAllowsVersionDowngrades` key in the currently installed
application's `Info.plist` remains supported for existing Nightly-to-Regular
switching. Applications that omit the key retain upstream downgrade protection
outside an explicit build-selection operation. New callers should use the
operation-scoped API instead of enabling that application-wide opt-in.

## Verification and distribution

Build this fork with macOS 27 and Xcode 27. CI and the draft-release workflow use
the `xcode-27` hosted runner and its selected toolchain. Draft assets and generated
package download URLs target the SakuraCord fork. Local artifacts can be
produced using `xcodebuild -project Sparkle.xcodeproj -scheme Distribution
-configuration Release -derivedDataPath build CODE_SIGN_IDENTITY=- build`.
The Distribution packaging step writes the SwiftPM archive and checksum.
Before publishing, set the package tag and checksum to that exact archive, and
publish it alongside its source tag. Do not run `make release` as a local preview
step: its tag-management script changes Git refs.

Security regression coverage is in `SUAppcastTest` and `SUInstallerTest`.
Run those suites together with `SUFeedSignatureVerifierTest` and
`SUUpdateValidatorTest` using the Sparkle scheme.

## Unreleased source updates

The source includes upstream 2.10.0 and the explicit-selection compatibility-bound
fix. CocoaPods support was removed with upstream. The SwiftPM manifest still
resolves the last published fork binary, `2.9.6-sakuracord.3`; updating source alone
does not publish a new binary or change SakuraCord’s pinned dependency. The next
fork distribution is versioned `2.10.0-sakuracord.1`.
