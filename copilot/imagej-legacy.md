# ImageJ Legacy Bridge - AI Coding Agent Instructions

## Project Overview
This is the **ImageJ Legacy Bridge** - a critical compatibility layer that enables backward compatibility between ImageJ2 (modern) and ImageJ 1.x (legacy). The bridge translates image data structures bidirectionally and wraps legacy plugins for execution in the modern framework.

## Core Architecture

### Three-Layer Translation System
1. **Converters** (`src/main/java/net/imagej/legacy/convert/`) - SciJava plugin-based converters for type transformation
   - `ImagePlusToDatasetConverter` / `DatasetToImagePlusConverter` - Core image conversions
   - `*ToImagePlusConverter` - String, Double, ImageDisplay to ImagePlus
   - ROI converters in `convert/roi/` - Handle region of interest translations
   
2. **Translators** (`src/main/java/net/imagej/legacy/translate/`) - Coordinate bidirectional image creation
   - `ImageTranslator` - Main entry combining `DisplayCreator` and `ImagePlusCreator`
   - Shares pixel data by reference when possible to avoid duplication

3. **Harmonizers** (`src/main/java/net/imagej/legacy/translate/`) - Synchronize metadata between representations
   - `Harmonizer` - Orchestrates all harmonizers to keep ImageJ1 and ImageJ2 in sync
   - `ColorTableHarmonizer`, `OverlayHarmonizer`, `PositionHarmonizer`, etc. - Specialized sync logic
   - Called during image updates to maintain consistency

### Central Services
- **`LegacyService`** (`LegacyService.java`) - Main service coordinating all legacy integration
  - Singleton pattern: Only one instance per JVM (ImageJ 1.x limitation)
  - Owns `LegacyImageMap` for tracking ImagePlus ↔ ImageDisplay associations
  - Initializes via static block calling `LegacyInjector.preinit()` to patch classes before loading

- **`IJ1Helper`** (`IJ1Helper.java`) - Encapsulates ALL direct `ij.*` class interactions
  - **Critical**: No other class should import `ij.*` packages to avoid class loader issues
  - Handles menu integration, macro execution, and UI operations
  - Manages class loader context for Event Dispatch Thread

- **`LegacyImageMap`** (`LegacyImageMap.java`) - Bidirectional mapping between `ImagePlus` and `ImageDisplay`
  - Uses `WeakHashMap` and `WeakReference` for memory management
  - Key constant: `IMP_KEY = "ij1-image-plus"` stored in Dataset metadata
  - One ImagePlus per ImageDisplay; if one Dataset has multiple displays, creates separate ImagePlus instances

### Patching and Initialization
**Critical Ordering**: ImageJ 1.x classes MUST be patched before they're loaded:
1. `LegacyInjector.preinit()` called in static initializer of `LegacyService`
2. Test classes call `LegacyInjector.preinit()` in their static blocks (see `ImagePlusConversionTest`)
3. `LegacyService` must NOT reference `ij.*` classes in its signature (fields, method params, returns)
4. All `ij.*` interactions delegated to `IJ1Helper` to maintain classloader separation

## Development Workflows

### Building and Testing
```bash
# Standard Maven build (uses parent pom-scijava for configuration)
mvn clean install

# Run tests (unit + integration tests in src/it/)
mvn test
mvn verify  # Includes failsafe integration tests

# CI uses scijava-scripts (see .github/build.sh and setup.sh)
# Java 8 required (see .github/workflows/build.yml)
```

### Writing Tests
**Always initialize Context properly**:
```java
static {
    LegacyInjector.preinit();  // MUST come first in static block
}

private Context context;

@Before
public void setUp() {
    context = new Context();  // Creates all services including LegacyService
    // Get services: context.service(ServiceClass.class)
}

@After
public void tearDown() {
    context.dispose();  // Critical for cleanup
}
```

### Adding Converters
Extend `AbstractLegacyConverter<Input, Output>`:
- Annotate with `@Plugin(type = Converter.class, priority = ...)`
- Override `canConvert()` to check `legacyEnabled()` first
- `LegacyService` injected automatically via `@Parameter`
- Use priorities to control conversion precedence (e.g., `Priority.VERY_HIGH` for unwrappers)

## Project Conventions

### Package Organization
- `command/` - Legacy command wrapping (`LegacyCommand`, `LegacyCommandInfo`)
- `convert/` - Type converters (plugin-based, SciJava framework)
- `translate/` - Image creation and harmonization logic
- `display/` - Display services for ImagePlus
- `plugin/` - Legacy plugin support and initialization
- `ui/` - User interface adapters
- `task/` - Task monitoring integration
- `search/` - Search bar integration

### Plugin Pattern
This codebase uses SciJava's plugin framework extensively:
- `@Plugin(type = Service.class)` for services
- `@Plugin(type = Converter.class)` for converters
- `@Parameter` for dependency injection (services auto-injected by Context)
- `@Parameter(required = false)` for optional dependencies

### Memory Management
- Uses `WeakHashMap` and `WeakReference` throughout to avoid memory leaks
- ImagePlus ↔ ImageDisplay mappings are weak to allow garbage collection
- Be cautious with strong references to ImageJ 1.x objects

### Thread Safety
- Synchronized methods common in wrapper classes (e.g., `TableWrapper`, `LegacyImageMap`)
- Event Dispatch Thread (EDT) context crucial for Swing operations
- `IJ1Helper.initialize()` sets EDT's context class loader

## Common Pitfalls

1. **Never import `ij.*` in new classes** - Always delegate through `IJ1Helper`
2. **Initialize test static blocks** - Must call `LegacyInjector.preinit()` before using ImageJ 1.x
3. **Dispose contexts** - Always call `context.dispose()` in test teardown
4. **Check legacy enabled** - Converters should verify `legacyEnabled()` before operating
5. **Single instance limit** - Only one `LegacyService` can be active per JVM

## Key Files to Reference
- `LegacyService.java` - Service initialization and lifecycle
- `IJ1Helper.java` - All ImageJ 1.x interaction patterns
- `LegacyImageMap.java` - Image mapping strategy
- `Harmonizer.java` - Metadata synchronization orchestration
- `ImageTranslator.java` - Image creation workflow
- Integration test: `src/it/ij1-quit/src/main/java/SystemExitIT.java`
