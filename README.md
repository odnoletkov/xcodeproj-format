# xcodeproj-format

Format Xcode project file (project.pbxproj) exactly the same way Xcode would
format it.

Xcode always writes project file in normalized format. External changes to the
file may leave it not normalized. If it is still valid, Xcode will read it just
fine - but will re-normalize on save. This causes unrelated changes in the file
to appear later in commits. Use this tool to keep the file normalized:

# Sample Uses

* Cleanup after merge - especially if conflicts were resolved
* Cleanup after modifying project file manually or with other tools
* Detect and reject misformatted or corrupted project files in CI
* `plutil` can be used to convert project file to JSON for further processing.
  This tool can be used to convert it back from JSON to the canonic format.

# Install

    brew install odnoletkov/tap/xcodeproj-format

# Build

    git clone https://github.com/odnoletkov/xcodeproj-format
    cd xcodeproj-format
    xcodebuild
    # Produces build/Release/xcodeproj-format

# Usage

```
xcodeproj-format path/to/foo.xcodeproj
```
```
xcodeproj-format path/to/foo.xcodeproj/project.pbxproj
```
```
xcodeproj-format path1 path2 ...
```
```
cd path/to/project
xcodeproj-format
```

# Limitations

* The tool uses Xcode's internal frameworks so it may break with new version
  (although this hasn't happened in years)
* ~1 second overhead to load and initialize Xcode state on each invocation

# TODO

* Daemonize to avoid initialization overhead for back-to-back invocations
* Add stdin-stdout mode

# Credits

* [xcproj](https://github.com/0xced/xcproj)
