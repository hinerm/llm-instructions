# SCIFIO AI Coding Agent Instructions

## Project Overview

SCIFIO (SCientific Image Format Input & Output) is an extensible Java framework for reading and writing N-dimensional scientific images. This is a **plugin-based architecture** built on the SciJava framework that separates image I/O into modular, composable components.

**Key Design Philosophy**: Each image format is decomposed into single-purpose components (Checker, Parser, Metadata, Reader, Writer, Translator) rather than monolithic format handlers. This modularity enables easier format addition and extensibility.

## Architecture & Core Concepts

### Format Component System

Every image format in SCIFIO is represented by a `Format` class containing 6 component types:

1. **Checker** - Determines if the format can handle a given file
2. **Metadata** - Data structure for format-specific metadata
3. **Parser** - Extracts metadata without reading pixels
4. **Reader** - Reads pixel data using metadata
5. **Writer** - Writes pixel data to output
6. **Translator** - Converts between metadata types (usually to/from format-agnostic representations)

**Implementation Pattern**: Components are nested static classes within a Format class:

```java
@Plugin(type = Format.class, name = "JPEG")
public class JPEGFormat extends AbstractFormat {
    public static class Metadata extends AbstractMetadata { ... }
    public static class Checker extends AbstractChecker { ... }
    public static class Parser extends AbstractParser<Metadata> { ... }
    public static class Reader extends ByteArrayReader<Metadata> { ... }
    public static class Writer extends AbstractWriter<Metadata> { ... }
}
```

**Location**: Format implementations are in `src/main/java/io/scif/formats/`

### SciJava Plugin & Context System

SCIFIO uses SciJava's dependency injection framework extensively:

- **@Plugin annotation**: Makes classes discoverable (Formats, Services, Translators all use this)
- **@Parameter annotation**: Automatic dependency injection - fields are populated by the Context
- **Context**: Central registry managing all services and plugins, ensures thread-safe component creation
- Components are **stateless** where possible; state lives in Metadata or Context

**Example**: Services are injected automatically:
```java
@Parameter
private DataHandleService handles;

@Parameter
private FormatService formatService;
```

### Terminology (SCIFIO vs Bio-Formats)

- **Dataset** (not "file"): Top-level container opened from a source
- **Image** (not "series"): Individual image within a dataset
- **Plane** (not "image"): Single 2D slice of pixel data

**N-dimensional Design**: Uses ImgLib2 `Axes` for arbitrary dimensionality, though many utility methods still assume 5D (XYZCT) for Bio-Formats compatibility.

### Image I/O Workflow

Standard SCIFIO workflow:
1. Use each Format's **Checker** to find compatible format
2. Use **Parser** to extract format-specific **Metadata** (no pixel reading)
3. Attach Metadata to **Reader** and open **Planes**
4. (Optional) Use **Translators** to convert metadata for writing to different format
5. Attach translated Metadata to **Writer** and save planes

## Development Patterns

### Creating New Formats

1. Extend `AbstractFormat` and implement `makeSuffixArray()` for supported file extensions
2. Create nested component classes (at minimum: Metadata, Checker, Parser, Reader)
3. Use `@Plugin(type = Format.class)` annotation on the Format class
4. Metadata should extend `AbstractMetadata`, Readers typically extend `ByteArrayReader<YourMetadata>`
5. Components access related components via `getFormat()` (from `HasFormat` interface)

### Service Access

The `SCIFIO` class provides convenient access to services:
```java
SCIFIO scifio = new SCIFIO();
FormatService formatService = scifio.format();
InitializeService initService = scifio.initializer();
```

**Key Services**:
- `FormatService`: Format discovery and component mapping
- `InitializeService`: Automated Reader/Writer setup with parsing
- `TranslatorService`: Metadata translation between formats
- `DataHandleService`: I/O stream abstraction

### ReaderFilters for Enhanced Functionality

Readers are often wrapped in `ReaderFilter` chains for added capabilities:
- `PlaneSeparator`: Separates multi-channel planes
- `ChannelFiller`: Fills missing channels
- `MinMaxFilter`: Computes min/max pixel values

**Pattern**: `InitializeService.initializeReader()` returns a `ReaderFilter`, not raw Reader.

### ImgLib2 Integration

Use `ImgOpener` to read images directly into ImgLib2 data structures:
```java
ImgOpener opener = new ImgOpener();
List<ImgPlus<?>> imgs = opener.openImgs(location);
```

`ImgPlus` wraps ImgLib2 `Img` with axis metadata, calibration, and name.

## Build & Test

**Build System**: Maven (`pom.xml`)
- Parent POM: `org.scijava:pom-scijava:38.0.1`
- Key dependencies: `scijava-common`, `imglib2`, `imagej-common`

**Build Commands**:
```bash
mvn clean install    # Full build with tests
mvn clean test       # Run tests only
```

**Test Structure**:
- Tests in `src/test/java/io/scif/`
- Use JUnit 4 (`@Test` annotation)
- Common pattern: extend base test classes like `AbstractSyntheticWriterTest`
- Test resources in `src/test/resources/io/scif/`

**CI**: GitHub Actions (`.github/workflows/build-main.yml`)

## Code Conventions

- **License Header**: Simplified BSD with `#L%` delimiters on all `.java` files
- **Generics**: Extensive use to capture component relationships (e.g., `Reader<M extends Metadata>`)
- **Context Awareness**: All components extend `AbstractSCIFIOPlugin`, gaining Context access
- **Thread Safety**: Components are designed to be stateless; use separate instances per thread
- **Metadata Serialization**: Metadata implements `Serializable` to cache expensive parsing operations

## Common Pitfalls

1. **Don't mix component types**: Each Format component has a specific role - don't put pixel reading in Parser
2. **Use Context for instantiation**: Don't use `new` for plugins - use `Format.createReader()`, etc.
3. **Handle both DataHandle and Location**: I/O abstraction supports various sources (files, HTTP, memory)
4. **Remember N-D design**: Avoid hardcoding assumptions about axis count or ordering
5. **Check Format priority**: Use `@Plugin(priority = ...)` to control format selection order when multiple formats match

## Quick Reference

- **Format examples**: `src/main/java/io/scif/formats/{JPEG,TIFF,DICOM}Format.java`
- **Service interfaces**: `src/main/java/io/scif/services/`
- **Core abstracts**: `src/main/java/io/scif/Abstract{Format,Reader,Writer,Parser}.java`
- **ImgLib2 bridge**: `src/main/java/io/scif/img/ImgOpener.java`
- **Package documentation**: `src/main/java/io/scif/package-info.java` (comprehensive overview)
