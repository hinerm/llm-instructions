# ImageJ Codebase Guide for AI Agents

## Project Overview

ImageJ is a **public domain** Java application for scientific image processing, first released in 1997. This is the original ImageJ (version 1.x), not ImageJ2. The codebase targets Java 6 compatibility while being built with Java 9+.

**Version**: 1.54p (see `ij/ImageJ.java` VERSION constant)

## Architecture

### Core Components

1. **`ij.ImagePlus`**: The central image container holding:
   - An `ImageProcessor` (2D image) OR an `ImageStack` (3D/4D/5D)
   - Metadata (calibration, file info)
   - References to `ImageWindow` (GUI) and `Roi` (region of interest)

2. **`ij.process.ImageProcessor`**: Abstract base for pixel manipulation with concrete implementations:
   - `ByteProcessor` (8-bit grayscale)
   - `ShortProcessor` (16-bit unsigned)
   - `FloatProcessor` (32-bit float)
   - `ColorProcessor` (32-bit RGB)

3. **`ij.IJ`**: Static utility class—the main API for logging, dialogs, running commands, and UI operations. Use `IJ.getInstance()` to get the `ImageJ` frame instance.

4. **`ij.ImageJ`**: Main application frame class. Contains VERSION and BUILD constants, window management, and command-line argument handling.

### Plugin System

ImageJ uses a **text-based menu configuration** (`IJ_Props.txt`) that maps menu items to plugin classes:

```plaintext
new01="Image...[n]",ij.plugin.Commands("new")
import01="Image Sequence...",ij.plugin.FolderOpener
```

**Two plugin interfaces**:
- `ij.plugin.PlugIn`: For plugins that acquire images or display windows
  ```java
  public void run(String arg)
  ```
- `ij.plugin.filter.PlugInFilter`: For plugins that process images
  ```java
  public int setup(String arg, ImagePlus imp)
  public void run(ImageProcessor ip)
  ```

Plugins declare capabilities via flag constants: `DOES_8G`, `DOES_16`, `DOES_RGB`, `DOES_STACKS`, etc.

### Macro System

- **Recorder** (`ij.plugin.frame.Recorder`): Records user actions as macro code. Check `Recorder.record` to see if recording is active.
- **Interpreter** (`ij.macro.Interpreter`): Executes ImageJ macro language scripts
- Macros in `macros/` directory; `StartupMacros.txt` runs on startup
- Use `IJ.run()` to execute commands programmatically (these can be recorded)

### ROI Hierarchy

All ROI types extend `ij.gui.Roi`:
- `OvalRoi`, `Line`, `PolygonRoi`, `TextRoi`, etc.
- `PolygonRoi` → subclasses: `PointRoi`, `FreehandRoi`, `RotatedRectRoi`, `EllipseRoi`

## Development Workflows

### Building

**Maven** (recommended):
```bash
mvn                  # Compile and package to target/ij.jar
mvn -Pexec          # Compile and run ImageJ
mvn javadoc:javadoc # Generate docs in target/apidocs/
```

**Ant**:
```bash
ant build           # Creates ij.jar
ant run             # Build and run ImageJ
ant clean           # Delete build artifacts
```

Build process:
1. Compiles `ij/**/*.java` targeting Java 6 bytecode
2. Copies resources: `IJ_Props.txt`, `images/`, `macros/`, pre-compiled `plugins/MacAdapter*.class`
3. Creates `ij.jar` with `MANIFEST.MF`

### Testing

**Important**: Tests are currently **skipped** by default (`maven.test.skip=true` in `pom.xml`)

- Test location: `tests/ij/`
- Uses JUnit 4 (`@Test` annotations)
- Example: `tests/ij/ImagePlusTest.java` (3400+ lines of comprehensive tests)

### CI/CD

GitHub Actions workflow (`.github/workflows/build-main.yml`):
- Runs on `master` branch and version tags
- Uses Java 11 (Zulu distribution) despite Java 6 target
- Custom scripts: `.github/setup.sh` and `.github/build.sh`
- Releases: Extracts version from `ij/ImageJ.java`, modifies POM, deploys to Maven Central if `BUILD` field is empty

## Coding Conventions

### Thread Safety

- Many image operations use `synchronized` methods/blocks
- `IJ.wait()` wraps `Thread.sleep()` for delays
- Event listeners use synchronized collections (`Vector`)

### Deprecation

- Legacy APIs marked with `@deprecated` JavaDoc (not `@Deprecated` annotation in older code)
- Example: `ImagePlus.getProcessor()` has side effects; internal code sometimes accesses `.ip` field directly

### Macro Recording

When adding recordable operations:
```java
if (Recorder.record)
    Recorder.record("commandName", arg1, arg2);
```

### Style Notes

- Old-style Java (predates modern idioms)
- Public fields common (e.g., `ImagePlus.changes`, `IJ.debugMode`)
- Static state used extensively (window management, clipboard, preferences)
- Minimal use of generics (Java 6 compatibility)

## Key File Locations

- **Entry point**: `ij/ImageJ.java` main class
- **Menu config**: `IJ_Props.txt` (embedded in jar)
- **Startup macros**: `macros/StartupMacros.txt`
- **Module descriptor**: `module-info.java` (exports all public packages)
- **Resources**: `images/` (microscope.gif, about.jpg), `macros/`

## External Integration

- **Maven coordinates**: `net.imagej:ij:1.x-SNAPSHOT`
- **License**: Public domain
- **Community**: Image.sc Forum, imagej@list.nih.gov mailing list
- **Docs**: https://imagej.net/ij/

## Common Patterns

### Creating an Image
```java
ImagePlus imp = IJ.createImage("title", "8-bit", 512, 512, 1);
ImageProcessor ip = imp.getProcessor();
```

### Accessing Current Image
```java
ImagePlus imp = WindowManager.getCurrentImage();
if (imp == null) {
    IJ.noImage();
    return;
}
```

### Running Commands
```java
IJ.run("Gaussian Blur...", "sigma=2");
IJ.run(imp, "Enhance Contrast", "saturated=0.35");
```

## Important Notes for AI Agents

1. **Java 6 target**: Avoid lambdas, try-with-resources, diamond operators, etc.
2. **No test execution**: Tests exist but are skipped in Maven build
3. **Version extraction**: CI reads VERSION/BUILD from source, not POM
4. **Plugin discovery**: Scans `plugins/` directory and JAR files with "_" in name
5. **Batch mode**: `Interpreter.batchMode` disables GUI during macro execution
6. **Socket communication**: Default port 57294 for inter-instance communication

When modifying code, preserve backward compatibility, maintain the public domain license, and follow the existing patterns—modern Java idioms are inappropriate for this Java 6-compatible codebase.
