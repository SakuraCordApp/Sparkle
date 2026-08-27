# SakuraCord Sparkle fork

This fork tracks Sparkle 2.9.6 and keeps its standard signed-feed, archive,
bundle-identity, and installation verification. Its only behavioral change is
an explicit opt-in for applications that intentionally move between release
tracks whose build numbers are not ordered globally.

Set the Boolean `SUAllowsVersionDowngrades` key in the currently installed
application's `Info.plist` to allow Sparkle's plain installer to replace it
with a signed update whose `CFBundleVersion` is lower. Applications that omit
the key retain upstream Sparkle's downgrade protection.
