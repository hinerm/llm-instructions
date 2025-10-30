# SciJava App Launcher - AI Coding Agent Instructions

## Purpose & Architecture

This library provides intelligent application bootstrapping for SciJava apps (especially [Fiji](https://fiji.sc/)). It handles three critical pre-launch tasks:

1. **Java Version Management**: Validates running JVM meets app requirements (`scijava.app.java-version-minimum`/`-recommended`), offering automated upgrades by downloading JVMs from `scijava.app.java-links`
2. **Dynamic ClassLoading**: Loads classes without system classpath via `ClassLauncher` (supports `-jarpath`, `-classpath` flags)
3. **User Experience**: Shows splash windows and version dialogs during startup

**Key Flow**: `ClassLauncher.main()` → `Java.check()` (validates/upgrades JVM) → `Splash.show()` → launches target application's main class via reflection

## System Property Contract

All configuration comes from system properties set by native launchers (e.g., [Jaunch](https://github.com/apposed/jaunch)):

- `scijava.app.name`: Application name for dialogs
- `scijava.app.java-root`: Bundled Java installations directory (enables managed upgrades)
- `scijava.app.java-links`: URL to platform-specific JVM download mappings (`linux-x64=https://...`)
- `scijava.app.java-version-minimum/recommended`: Version strings (e.g. "21" or "1.8.0_202")
- `scijava.app.splash-image`: ClassLoader resource path for splash screen
- `scijava.app.look-and-feel`: Swing L&F class (e.g., `com.formdev.flatlaf.FlatLightLaf`)
- `scijava.app.unlock-modules`: If true, calls `ReflectionUnlocker.unlockAll()` to bypass JPMS encapsulation

See `LaunchDemo.java` for a working example of property setup.

## Critical Patterns

### Version Comparison
Use `Versions.compare(v1, v2)` for all version logic. Supports both major-only ("11") and dotted strings ("21.0.4"). The `Versions.classVersionToJavaVersion()` converts bytecode versions (e.g., "52.0" → "1.8").

### Java Upgrade Decision Tree
`Java.check()` follows this logic (see `thoughts.txt` for design rationale):

```
Running version vs. required/recommended:
├─ GOOD (curr >= recm) → Proceed to launch
├─ ADEQUATE (recm > curr >= reqd) → Offer upgrade if bundled/managed
└─ BAD (reqd > curr) → Strong upgrade prompt or exit

Bundled vs. External JVM:
├─ isManaged(): JVM is in scijava.app.java-root AND running from there
├─ isBundled(): JVM found under app directory structure
└─ External: User-controlled installation → warn but don't auto-upgrade
```

### Resource Loading Strategy
`ClassLoaders` utility provides fallback chains for robust class/resource loading:
1. Preferred ClassLoader (if provided)
2. Thread context ClassLoader
3. System ClassLoader
4. Fallback class's ClassLoader (if provided)

Use `ClassLoaders.loadClass()` and `ClassLoaders.getResource()` instead of direct ClassLoader calls.

### User Dialog Persistence
`Java.askIfAllowed()` checks Java Preferences before showing dialogs. Keys like `skipVersionWarning` respect "Never ask again" choices. Clear with `Preferences.userNodeForPackage(Java.class).clear()` during development.

## Development Workflow

**Build**: `mvn clean install` (requires Java 8+, targets Java 8 bytecode)
**Test**: `mvn test` (includes `LaunchDemo` for manual testing)
**Coverage**: `mvn jacoco:report` → `target/site/jacoco/index.html`
**CI**: Uses GitHub Actions with Java 8 (Zulu) on Ubuntu/Windows

**Key Files**:
- `ClassLauncher.java`: Entry point, command-line parsing, reflection-based launch
- `Java.java`: Version checking, upgrade flows, JVM installation detection
- `Downloader.java`: Async downloads with progress reporting
- `Archives.java`: Extracts downloaded JVM archives
- `Config.java`: Simple key=value file I/O (used for persisting Java paths)

## Common Gotchas

1. **UnsupportedClassVersionError Handling**: When caught in `ClassLauncher.launch()`, triggers `Java.informAndMaybeUpgrade()` to handle "class too new" scenarios
2. **Module Unlocking**: `ReflectionUnlocker` requires `--add-opens=java.base/java.lang=ALL-UNNAMED` to function. Only enabled via `scijava.app.unlock-modules=true`
3. **Splash Threading**: `Splash` updates run on EDT via `EventQueue.invokeLater()` to avoid Swing concurrency issues
4. **Path Separators**: `-jarpath` supports both `:` (Unix) and `;` (Windows) separators

## Testing New Features

Before modifying upgrade logic, run `LaunchDemo` with different `java-version-minimum/recommended` values. Comment out `Preferences.clear()` to test "Never ask again" persistence.

For testing downloads, point `scijava.app.java-links` to a controlled URL and verify `Archives.extract()` handles both `.tar.gz` and `.zip` formats.
