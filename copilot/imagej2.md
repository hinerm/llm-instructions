# ImageJ2 Development Guide for AI Agents

## Project Overview

ImageJ2 is a **gateway aggregator** that bundles the complete ImageJ2 ecosystem. This repository contains minimal source code (only `src/main/java/net/imagej/{ImageJ.java, Main.java, app/ToplevelImageJApp.java}`) but coordinates a complex plugin-based architecture through Maven dependencies.

**Key Insight**: Most functionality lives in separate repositories. This repo's primary role is dependency orchestration and providing a unified entry point via the `ImageJ` gateway class.

## Architecture Patterns

### SciJava Plugin Framework
The entire ecosystem is built on SciJava's annotation-based plugin system:

- **Service Discovery**: Services are auto-discovered via `@Plugin(type = Service.class)` annotations
- **Dependency Injection**: Use `@Parameter` for automatic service injection (not constructor injection)
- **Context Management**: All components share a `Context` - never create services manually
- **Gateway Pattern**: `ImageJ` class (extends `AbstractGateway`) provides typed accessor methods for services

Example from `ImageJ.java`:
```java
public OpService op() {
    return get(OpService.class);  // Retrieves from Context
}
```

### Three-Tier Service Hierarchy
Services must implement exactly ONE marker interface (enforced by `ServiceCompletenessTest.testMarkerInterfaces()`):

1. `ImageJService` - ImageJ2-specific services
2. `SCIFIOService` - Image I/O services  
3. `SciJavaService` - Framework-level services

**Never** implement multiple marker interfaces or tests will fail.

### Version Composition Pattern
`ToplevelImageJApp` demonstrates dynamic version reporting by detecting and combining ImageJ2 + original ImageJ versions at runtime:
- Uses `Class.forName()` to optionally detect `LegacyService`
- Higher `priority` annotation overrides base `ImageJApp` plugin
- Returns composite version string: `"2.17.1/1.54f"` format

## Build System & Development Workflow

### Maven Commands
```bash
# Standard build
mvn clean install

# Build with uber-jar (all dependencies bundled)
mvn clean install -Pdeps

# Generate dependency graphs (requires graphviz)
bin/gen-graphs.sh
```

### Dependency Management
- **Parent POM**: Inherits from `pom-scijava` v42.0.0 which manages all version properties
- **Scope Strategy**: Core deps are compile scope; plugins/implementations are runtime scope
- **Assembly Profile**: The `deps` profile creates `imagej-VERSION-all.jar` with sources using `src/main/assembly/all.xml`

### CI/CD
- **Platform**: GitHub Actions (`.github/workflows/build.yml`)
- **Java Version**: Java 8 (Zulu distribution) for backwards compatibility
- **Scripts**: `.github/setup.sh` and `.github/build.sh` pull from `scijava/scijava-scripts` repo

## Testing Conventions

### Service Completeness Testing
`ServiceCompletenessTest.java` validates the plugin ecosystem:
- Lists all expected service implementations explicitly
- Verifies each service can be retrieved from Context
- Ensures marker interface exclusivity (one per service)

When adding a new service dependency:
1. Add to `pom.xml` dependencies
2. Add implementation class to `testServices()` list
3. Verify it implements correct marker interface

### Test Structure
- Setup: `ctx = new Context(ImageJService.class)` - creates full ImageJ2 context
- Teardown: `ctx.dispose()` - always clean up to prevent resource leaks
- Pattern: Use `ctx.service(MyService.class)` to retrieve services, never `new MyService()`

## Code Style & Conventions

### License Headers
All Java files MUST include the simplified BSD license header:
```java
/*
 * #%L
 * ImageJ2 software for multidimensional image processing and analysis.
 * %%
 * Copyright (C) 2009 - 2025 ImageJ2 developers.
 * %%
 * [License text...]
 * #L%
 */
```
Run `bin/check-headers.pl` to validate. Known authors are whitelisted in the script.

### Package Structure
```
net.imagej          - Gateway class and main entry point
net.imagej.app      - Application metadata (ImageJApp, ToplevelImageJApp)
```

### Author Tags
All classes require `@author` Javadoc tags with names from the known authors list in `bin/check-headers.pl`.

## Integration Points

### Multi-Language Support
ImageJ2 is designed for embedding:
- **Python**: Via PyImageJ (`pyimagej` on PyPI)
- **JavaScript**: Via npm `imagej` module  
- **JVM Languages**: Direct Java API, or via GraalVM for Ruby/R/etc.
- **Headless**: Pass `--headless` flag; context auto-disposes after execution

### Legacy ImageJ Integration
The `imagej-legacy` dependency (runtime, optional) provides backwards compatibility:
- Dynamically detected via reflection in `ToplevelImageJApp.getLegacyVersion()`
- Allows original ImageJ plugins to work unmodified
- Bridge between `ij.ImagePlus` (original) and `Dataset` (ImageJ2)

### SCIFIO for I/O
SCIFIO handles image file formats (100+ via Bio-Formats):
- Auto-detected by `File > Open` (no special imports needed)
- Falls back to original ImageJ I/O if format unsupported
- `ImageJ` gateway provides `scifio()` accessor for direct API access

## Common Pitfalls

1. **Don't instantiate services directly** - always retrieve from Context
2. **Don't forget Context.dispose()** - causes resource leaks in tests
3. **Runtime dependencies are invisible to IDEs** - check `pom.xml` for complete dep tree
4. **Version conflicts**: If updating deps, ensure compatibility with `pom-scijava` versions
5. **Classpath in scripts**: `bin/ImageJ.sh` has complex classpath assembly - understand before modifying

## Key Files Reference

- `pom.xml` - Complete dependency specification (lines 300-500 list all runtime deps)
- `src/main/java/net/imagej/ImageJ.java` - Main gateway; add service accessors here
- `src/test/java/net/imagej/app/ServiceCompletenessTest.java` - Update when adding services
- `bin/populate-app.sh` - Builds application bundle (ImageJ2.app)
- `.github/workflows/build.yml` - CI configuration

## Documentation

- Main site: https://imagej.net/
- Developer docs: https://imagej.net/develop/
- Source building: https://imagej.net/develop/source
- Report bugs: https://imagej.net/discuss/bugs
- Forum: https://forum.image.sc/tag/imagej
