# ImageJ Updater - Developer Guide

## Project Overview

The ImageJ Updater is a plugin update system that manages installations across multiple update sites. It tracks files in an ImageJ installation, computes checksums, compares with remote manifests (`db.xml.gz`), and handles uploads/downloads with dependency resolution.

**Core Architecture:**
- `FilesCollection`: Central database of `FileObject`s representing managed files. Acts as a `LinkedHashMap<String, FileObject>`.
- `FileObject`: Represents a single file with status (`INSTALLED`, `UPDATEABLE`, `MODIFIED`, etc.) and action (`UPDATE`, `INSTALL`, `UNINSTALL`).
- `UpdateSite`: Remote repositories with URLs and upload credentials. The default is "ImageJ" at `https://update.imagej.net/`.
- `Checksummer`: Scans specific directories (see below) and computes checksums, handling multiple file versions.
- `XMLFileReader`/`XMLFileWriter`: Parse and write compressed `db.xml.gz` manifests containing file metadata.

## Critical Directory Structure

The Updater **only recognizes files** in these directories (from `Checksummer.directories`):
- `jars/`, `retro/`, `misc/` - `.jar` and `.class` files
- `config/` - `.toml`, `.class`, `.py`, `.txt`  
- `plugins/` - `.jar`, `.class`, scripts (`.ijm`, `.py`, `.rb`, `.clj`, `.js`, `.bsh`, `.groovy`)
- `scripts/`, `macros/` - script files
- `models/`, `luts/`, `images/` - resource files
- `lib/`, `mm/`, `mmautofocus/`, `mmplugins/` - native libraries (all extensions)
- `Contents/` - macOS bundles (`.icns`, `.plist`)
- `licenses/` - license files

Files outside these paths are **invisible** to the updater.

## Platform Naming Conventions

The updater uses **short platform names** for OS+architecture combos (see README.md):
- Linux: `linux64`, `linux-arm64`, `linuxx` (group)
- macOS: `macos64`, `macos-arm64`, `macosx` (group)  
- Windows: `win64`, `win-arm64`, `winx` (group)

Platform-specific files go in subdirectories like `jars/win64/`, `lib/linux-arm64/`.  
Groups (ending in 'x') match all architectures for that OS.

Launchers (in `Platforms.LAUNCHERS`):
- Jaunch: `fiji-linux-x64`, `config/jaunch-windows-arm64.exe`
- Legacy ImageJ Launcher: `ImageJ-win64.exe`, `Contents/MacOS/ImageJ-macosx`

All files in `.app` folders are assigned to the `macosx` platform group.

## Checksum Philosophy

**JAR checksums ignore build-time metadata** to avoid spurious updates:
- `.properties` files: dates in comments are filtered (`SkipHashedLines`)
- `MANIFEST.MF`: filters `Archiver-Version`, `Built-By`, `Build-Jdk`, etc. (`FilterManifest`)
- Entries are sorted before hashing (`JarEntryComparator`)

Special case: `plugins/Fiji_Updater.jar` uses unfiltered checksums.

## Testing Infrastructure

Tests use **temporary filesystem hierarchies** simulating ImageJ installations:
- `UpdaterTestUtils.initialize()`: Creates `ij-root/` (local) and `ij-web/` (remote update site)
- `writeJar()`: Creates fake JAR files with specified contents
- `FilesCollection.prefix(path)`: Resolves paths relative to the test ImageJ root
- Tests execute `CommandLine.main()` to perform operations
- The `.checksums` cache is deleted before each test run

Example pattern from `UpdaterTest`:
```java
FilesCollection files = initialize("jars/hello.jar");
writeJar(files, "jars/hello-2.0.jar", "new-file", "empty");
files = main(files, "upload", "--update-site", "ImageJ", "jars/hello-2.0.jar");
```

## Build & Test Commands

**Maven Build:**
```bash
mvn clean install          # Build and run tests
mvn test                   # Run tests only
mvn test -Dtest=UpdaterTest#testUpdateTheUpdater  # Single test
```

**Test Coverage:**
```bash
mvn clean test jacoco:report
open target/site/jacoco/index.html
```

The project inherits from `pom-scijava` parent POM (v43.0.0), which configures license headers, deployment, and release profiles.

## Uploader Plugin System

Uploaders are **SciJava plugins** implementing `Uploader` interface:
- Annotate with `@Plugin(type = Uploader.class)`
- Discovered via `UploaderService` at runtime
- `FileUploader`: Default file-based uploader
- Custom uploaders can support protocols like SSH/SFTP/WebDAV

The `FilesUploader` class handles the upload workflow:
1. Computes timestamps (lock coordination)
2. Builds `Uploadable` list from staged files
3. Invokes protocol-specific uploader
4. Writes `db.xml.gz` to remote site

## Common Pitfalls

1. **Version skew**: The updater can update *itself*. Use `Installer.updateTheUpdater()` which stages the new JAR in an `update/` directory for next launch.

2. **Dependency cycles**: The `DependencyAnalyzer` detects circular dependencies across update sites.

3. **File conflicts**: Multiple versions of the same component trigger conflict resolution (see `Checksummer.handle()`). The updater flags obsolete copies and locally-modified files.

4. **ClassLoader issues**: `FilesUploader.setClassLoaderIfNecessary()` ensures plugins can find SciJava context classes.

5. **Platform detection**: `Platforms.inferActive()` checks for launchers in the installation to determine active platforms.

## Key Workflows

**Updating files:**
1. `FilesCollection.read()` loads remote `db.xml.gz` via `XMLFileReader`
2. `Checksummer` scans local directories, compares with database
3. User stages changes via `FileObject.stageForUpdate()`
4. `Installer` downloads to `update/` directory, moves on next launch

**Uploading to update site:**
1. `FileObject.stageForUpload()` marks files
2. `FilesUploader` constructs `Uploadable` list
3. `Uploader.upload()` transfers files + updated `db.xml.gz`
4. Timestamp locks prevent concurrent uploads

**Adding update sites:**
```bash
# Command-line
java -jar jars/imagej-updater.jar add-update-site MySite https://example.com/updates/
```

## Debugging Tips

- Set `UpdaterUserInterface` for custom logging (default: `ConsoleUserInterface`)
- Inspect `FilesCollection.conflicts` for unresolved issues
- Check `.checksums` cache in ImageJ root (deleted on clean checksums)
- Use `UpdaterTestUtils.show()` to launch Swing UI for test inspection (requires `ui/swing` module)
- `Diff` class can compare JARs, run `javap`, and detect class version mismatches
