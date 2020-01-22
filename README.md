# xcodeproj-format

Format Xcode project file (project.pbxproj) exactly the same way Xcode would
format it.

Some operations can leave project file in non-normalized state. Xcode will read
it just fine - but it will always save it back in normalized format. This
causes unrelated changes in the project file to appear later in commits. Use
this tool to clean-up and avoid this problem:

* After merge - especially if conflicts were resolved
* After modifying project file manually or with other tools
* Detect and reject misformatted or corrupted project files in CI

# Build

    git clone https://github.com/odnoletkov/xcodeproj-format
    cd xcodeproj-format
    xcodebuild
    # Produces build/Release/xcodeproj-format

# Usage

```
xcodeproj-format path/to/App.xcodeproj
```
```
xcodeproj-format path/to/App.xcodeproj/project.pbxproj
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

# Credits

* [xcproj](https://github.com/0xced/xcproj)
