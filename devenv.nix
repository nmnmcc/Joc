{ pkgs, ... }:

{
  # Xcode supplies the Apple SDK; Devenv supplies the command-line tools.
  apple.sdk = null;

  packages = with pkgs; [
    xcodegen
    swiftformat
    swiftlint
    xcbeautify
  ];

  unsetEnvVars = [
    "CC"
    "CXX"
    "LD"
    "AR"
    "AS"
    "NM"
    "OBJCOPY"
    "RANLIB"
    "STRIP"
  ];

  scripts = {
    generate.exec = "xcodegen generate --spec project.yml";
    format.exec = "swiftformat --swift-version 6 Sources";
    lint.exec = "swiftlint lint --strict";
    build.exec = ''
      set -o pipefail
      xcodebuild \
        -project Anylock.xcodeproj \
        -scheme Anylock \
        -sdk iphonesimulator \
        -destination 'generic/platform=iOS Simulator' \
        CODE_SIGNING_ALLOWED=NO \
        build | xcbeautify
    '';
  };
}
