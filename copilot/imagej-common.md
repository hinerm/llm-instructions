# ImageJ Common - AI Coding Agent Instructions

> **Related files**: Start with `scijava-foundation.md` for shared SciJava concepts. See `imglib2.md` for the underlying image data structures, and `scijava-common.md` for the plugin framework.

## Project Overview

ImageJ Common is the core library for ImageJ2, providing:
- Image data model built on **ImgLib2** (the underlying N-dimensional image library)
- Image display logic for user interfaces
- Plugin architecture via **SciJava**
- Service infrastructure for dependency injection

**Key distinction**: This is a *library*, not an application. It provides reusable components consumed by ImageJ2 and other projects.

## Architecture & Data Model

### Core Data Hierarchy

```
Data (interface)
├── Dataset - wraps ImgLib2's ImgPlus, the primary image data structure
│   └── DefaultDataset - concrete implementation
└── Overlay - vector graphics (ROIs, shapes)
    └── AbstractOverlay
```

**Critical concept**: `Dataset` wraps `ImgPlus<? extends RealType<?>>`, which wraps `Img`. Understanding this nesting is essential:
- `Img`: Raw ImgLib2 pixel container
- `ImgPlus`: Adds metadata (axes, calibration, color tables)
- `Dataset`: ImageJ2's API with plane access, RGB support, dirty state tracking

### Axis System

Use `Axes` class for dimension types, NOT raw strings:
```java
// Standard axes: Axes.X, Axes.Y, Axes.Z, Axes.TIME, Axes.CHANNEL
new AxisType[] { Axes.X, Axes.Y, Axes.CHANNEL }
```

## SciJava Plugin Architecture

### Service Pattern

All services follow this pattern:
1. **Interface** extends `ImageJService` (e.g., `DatasetService`)
2. **Implementation** extends `AbstractService`, annotated with `@Plugin(type = Service.class)`
3. **Dependency Injection** via `@Parameter` fields (NOT constructor injection)

Example from `DefaultDatasetService`:
```java
@Plugin(type = Service.class)
public final class DefaultDatasetService extends AbstractService 
    implements DatasetService {
    
    @Parameter
    private ScriptService scriptService;
    
    @Parameter
    private LogService log;
}
```

### Context & Lifecycle

**Always use `Context` for dependency injection**:
```java
// In tests
Context context = new Context(DatasetService.class);
DatasetService ds = context.service(DatasetService.class);
// ... use service ...
context.dispose();  // MUST dispose to prevent resource leaks
```

**In plugins/services**: Call `context.inject(this)` to populate `@Parameter` fields.

### Plugin Discovery

Plugins are discovered via `@Plugin` annotation + JSON metadata in `META-INF/json/org.scijava.plugin.Plugin`.
- Build generates this metadata automatically
- Commands, Services, DataTypes, MinMaxMethods, etc. all use this mechanism

## Development Workflows

### Building & Testing

```bash
# Build with Maven (standard SciJava build)
mvn clean install

# Run tests
mvn test

# Skip tests for faster builds
mvn clean install -DskipTests
```

**CI uses GitHub Actions** with scripts from `scijava/scijava-scripts`:
- `.github/setup.sh` - CI environment setup
- `.github/build.sh` - CI build script

### Testing Patterns

1. **Create Context in @Before**, dispose in @After:
```java
@Before
public void setUp() {
    context = new Context(DatasetService.class);
    datasetService = context.service(DatasetService.class);
}

@After
public void tearDown() {
    context.dispose();  // Critical!
}
```

2. **Use services for Dataset creation**, don't construct directly:
```java
Dataset ds = datasetService.create(
    new long[] { 512, 512, 3 },
    "My Image",
    new AxisType[] { Axes.X, Axes.Y, Axes.CHANNEL },
    8,  // bits per pixel
    false,  // signed
    false   // floating point
);
```

## Common Patterns & Conventions

### Deprecated I/O Methods

`DatasetService.open()` and `.save()` are **deprecated**. They throw `UnsupportedOperationException` directing users to `io.scif.services.DatasetIOService` instead. Don't use or recommend these methods.

### Event Publishing

Data objects publish events via `EventService`:
- `DatasetCreatedEvent`, `DatasetUpdatedEvent`, `DatasetRestructuredEvent`, etc.
- Use `publish(event)` from `AbstractData`

### Plane Access

Datasets support plane-by-plane pixel access (primarily for planar image backends):
```java
Object plane = dataset.getPlane(planeNumber);
dataset.setPlane(planeNumber, newPlane);
```

### Type Handling

ImgLib2 uses **generic types** heavily (`RealType`, `NumericType`, etc.):
- `DataTypeService` maps between type classes and ImageJ `DataType` objects
- Services often use wildcards: `ImgPlus<? extends RealType<?>>`

## Key Dependencies

- **ImgLib2** (`net.imglib2`): Core image library - multi-dimensional data structures
- **SciJava Common** (`org.scijava`): Plugin framework, Context, Services, Events
- **SciJava Table** (`org.scijava.table`): Table data structures
- **UDUNITS** (`edu.ucar.udunits`): Unit conversion via `DefaultUnitService`

Parent POM: `org.scijava:pom-scijava:38.0.1` - provides most dependency versions.

## Resources & LUTs

Lookup tables (LUTs/color tables) are in `src/main/resources/luts/`:
- Loaded dynamically by `DefaultLUTService`
- Auto-registered as modules (commands) at runtime
- Organized in subdirectories: `NCSA PalEdit/`, `WCIF/`

## What NOT to Do

- ❌ Don't construct `DefaultDataset` directly - use `DatasetService.create()`
- ❌ Don't forget to dispose `Context` in tests (causes leaks)
- ❌ Don't use `DatasetService.open()/save()` - they're deprecated
- ❌ Don't hardcode axis names - use `Axes.X`, `Axes.Y`, etc.
- ❌ Don't use constructor injection for services - use `@Parameter` fields
- ❌ Don't access `@Parameter` fields before Context injection completes

## Quick Reference

**Creating a Dataset**:
```java
Dataset ds = datasetService.create(
    new long[] { width, height }, 
    "name", 
    new AxisType[] { Axes.X, Axes.Y }, 
    8, false, false
);
```

**Getting typed ImgPlus**:
```java
ImgPlus<UnsignedByteType> typed = dataset.typedImg(new UnsignedByteType());
```

**Testing setup**:
```java
context = new Context(DatasetService.class);
try {
    // test code
} finally {
    context.dispose();
}
```
