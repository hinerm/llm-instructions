# Fiji Copilot Instructions

> **Related files**: Start with `scijava-foundation.md` for shared concepts. See `imagej2.md` for the core application architecture. For Python integration, see `pyimagej.md`.

## Project Overview

Fiji is a "batteries-included" distribution of ImageJ for life sciences—a scientific image processing application built on Java. This repository is the top-level project that **bundles** runtime plugins and manages releases, not a monolithic codebase.

**Key principle**: Fiji = ImageJ + SciJava ecosystem + 100+ plugin dependencies. Most functional code lives in separate GitHub repos under the `fiji/` and `scijava/` organizations. This repo primarily manages dependencies, packaging, and distribution.

## Architecture

### Distribution Model
- **Main class**: `sc.fiji.Main` (simple launcher wrapping `net.imagej.ImageJ`)
- **Plugin architecture**: Uses SciJava's plugin discovery system. Plugins are Maven dependencies declared in `pom.xml` as `<scope>runtime</scope>`
- **Dependency management**: Inherits from `pom-scijava` parent POM (version managed centrally)
- **Component repositories**: Individual plugins (e.g., `TrackMate`, `3D_Viewer`) live in separate repos; changes to plugin code happen there, not here

### Launcher System
Fiji uses **Jaunch** (next-gen launcher, replacing legacy ImageJ launcher):
- Config: `config/jaunch/fiji.toml` - defines CLI options, modes (Java/Python)
- Python bridge: `config/jaunch/fiji.py` - enables `--python` mode via PyImageJ
- Environment: `config/environment.yml` - Conda environment for Python integration

### Directory Structure
```
pom.xml              # Maven project: dependency aggregation only
src/main/java/       # Minimal: just sc.fiji.Main and fiji.Main
bin/                 # Shell/Python scripts for builds, releases, utilities
config/              # Jaunch launcher config + conda environment
plugins/             # ImageJ 1.x style plugins (macros, scripts)
macros/              # ImageJ macros and toolsets
scripts/             # Structured scripts (File/, Image/, Plugins/)
luts/                # Color lookup tables
```

## Build & Development Workflow

### Standard Maven Build
```bash
mvn clean install         # Build Fiji JAR + copy all deps to local Fiji.app
mvn -Dscijava.app.directory=/path/to/Fiji.app  # Install into specific Fiji.app
```

**Critical**: The Maven build with `scijava.app.directory` property auto-copies JARs to the app structure (via SciJava Maven plugin). This is how you update a running Fiji installation.

### Updating an Existing Fiji.app
```bash
bin/populate-app.sh /path/to/Fiji.app
```
This script **erases all JARs** in the target, runs `mvn -Dscijava.app.directory`, then relocates platform-specific libraries (Bio-Formats libs, native binaries).

**Native library handling**: Multi-platform natives (JOGL, javacv) are fetched separately per platform (`win64`, `macosx`, `linux64`) into `jars/{platform}/` subdirs.

### Release Process
```bash
bin/make-release-archives.sh <version> <commit-hash>
```
1. Downloads template Fiji.app bundle for each platform
2. Runs `populate-app.sh` to inject updated JARs
3. Removes non-matching platform folders
4. Creates `fiji-{version}-{platform}.zip` archives

### CI Pipeline
- **Workflow**: `.github/workflows/build.yml`
- **Setup**: Downloads `ci-setup-github-actions.sh` from `scijava/scijava-scripts` (shared SciJava CI config)
- **Build**: Downloads `ci-build.sh` (standard Maven build + deploy to maven.scijava.org)
- **Java version**: Java 8 for builds (for widest compatibility), but runtime targets OpenJDK 21

## Dependency Management Conventions

### Adding a Plugin Dependency
1. **Always use `<scope>runtime</scope>`** for plugin JARs (they're loaded dynamically, not compile-time)
2. Group by organization: Fiji plugins (`sc.fiji`), ImageJ plugins (`net.imagej`), third-party
3. **Do NOT specify versions here** - inherit from `pom-scijava` parent POM
4. If a plugin needs a new version, update `pom-scijava` first (in a separate repo)

### Dependency Quirks
- **Classpath conflicts**: Some artifacts clash (e.g., `antlr:antlr` vs `org.antlr:antlr`). See `populate-app.sh` for manual `mvn dependency:copy` workarounds
- **Bio-Formats libs**: Incorrectly land in `jars/`, get moved to `jars/bio-formats/` by `populate-app.sh`
- **Plugin relocations**: Some JARs must be in `plugins/` not `jars/` (e.g., `Correct_3D_Drift`, `KymographBuilder`, `bigdataviewer_fiji`)

## Python Integration

Fiji supports **dual-mode launch** (Java or Python):
- `--python` flag activates Python mode via `config/jaunch/fiji.py`
- Uses **PyImageJ** to wrap ImageJ in Python (requires `pyimagej>=1.7.0`)
- Python environment defined in `config/environment.yml` (includes napari, scikit-image, ndv)
- **Appose** integration for bidirectional Python↔Java calls (git dependency in environment.yml)

## Common Pitfalls

1. **Plugin code not here**: If fixing a bug in a specific plugin, you need to edit that plugin's repo (e.g., `fiji/TrackMate`), not this one
2. **JAR file naming**: Plugin JARs follow `{artifactId}-{version}.jar`. If you see `fiji-2.17.0.jar`, that's THIS project
3. **Maven wrapper**: `bin/maven.sh` auto-downloads Maven 3.0.4 if not found (legacy; prefer system Maven)
4. **Legacy launcher**: `bin/ImageJ.sh` is deprecated; kept for backwards compatibility. Modern installs use Jaunch

## Testing & Debugging

- **Run Fiji from IDE**: Execute `sc.fiji.Main` with `-Dplugins.dir=/path/to/Fiji.app` to access full plugin set
- **Headless mode**: Add `--headless` flag (defined in Jaunch config)
- **Debug mode**: `--jdb` or standard JVM debug args before `--` separator in CLI
- **No unit tests here**: This is a distribution project. Tests live in component repos

## Key External Dependencies

- **ImageJ**: `net.imagej:imagej` (ImageJ2) + `net.imagej:ij` (ImageJ 1.x)
- **SciJava**: `org.scijava:scijava-common`, `app-launcher`
- **ImgLib2**: Core image processing library (transitive dependency)
- **Bio-Formats**: Multi-format microscopy image I/O (runtime dep)
- **JOGL**: Java 3D rendering (platform-specific natives)

## Useful Scripts

- `bin/which-jar-has-plugin.py` - Find which JAR contains a plugin class
- `bin/find-jar-for-class.bsh` - Locate JAR for a given class
- `bin/upload-plugin-from-maven.sh` - Upload plugin to update site
- `bin/cleanup.sh` - Remove build artifacts

## Support & Community

- **Forum**: https://forum.image.sc/tag/fiji (primary support channel)
- **Chat**: https://imagesc.zulipchat.com/#narrow/stream/327238-Fiji
- **Issues**: GitHub issues for THIS repo are distribution problems; plugin bugs go to their respective repos
