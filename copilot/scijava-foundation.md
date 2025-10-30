# SciJava Foundation - Shared Concepts

## Overview

This document covers foundational concepts shared across all SciJava-based projects. Reference this file when working on any ImageJ2, SciJava, or SCIFIO component.

## SciJava Plugin System

### Plugin Discovery

SciJava uses compile-time annotation processing to discover plugins at runtime:

- **@Plugin annotation**: Makes classes discoverable
  ```java
  @Plugin(type = Service.class)
  public class MyService extends AbstractService implements MyServiceAPI {
      // ...
  }
  ```

- **Plugin types**: `Service`, `Command`, `Converter`, `Tool`, `ScriptLanguage`, etc.
- **Priority**: Control selection order via `priority` attribute (see `org.scijava.Priority` constants)
- **Metadata location**: `META-INF/json/` (generated at build time)

### Dependency Injection

Use `@Parameter` for automatic dependency injection (NOT constructor injection):

```java
@Parameter
private LogService log;

@Parameter
private DatasetService datasetService;

@Parameter(required = false)  // Optional dependencies
private UIService uiService;
```

**In Services**: Dependencies are auto-injected by the Context
**In Commands/Plugins**: Call `context.inject(this)` if needed manually

### Context Management

The `Context` is the application-level IoC container:

```java
// Create context with specific services
Context context = new Context(DatasetService.class, OpService.class);

// Retrieve services
DatasetService ds = context.getService(DatasetService.class);
// or
DatasetService ds = context.service(DatasetService.class);

// ALWAYS dispose when done
context.dispose();  // Prevents resource leaks
```

**Critical**: Never create services manually with `new` - always retrieve from Context.

## Maven Build System

### Standard Commands

```bash
# Standard build
mvn clean install

# Build without tests
mvn clean install -DskipTests

# Run specific test
mvn test -Dtest=MyTest#testMethod

# Skip enforcer for faster iteration
mvn -Denforcer.skip clean install
```

### Parent POM

Most projects inherit from `pom-scijava` which:
- Manages all version properties
- Provides shared build configuration
- Defines standard plugin versions
- Sets Java compatibility (typically Java 8)

**Never specify dependency versions** in project POMs - inherit from parent.

### Dependency Scopes

- **compile**: Core dependencies needed at compile time
- **runtime**: Plugins discovered at runtime (most SciJava plugins)
- **test**: Test-only dependencies

## CI/CD Patterns

### GitHub Actions

Standard workflow (`.github/workflows/build.yml`):
- Uses scripts from `scijava/scijava-scripts` repository
- `.github/setup.sh` - Downloads CI setup script
- `.github/build.sh` - Downloads build script
- Java 8 for builds (Zulu distribution)
- Deploys to SciJava Maven repository on tagged releases

## Testing Conventions

### JUnit Version

Most projects use **JUnit 4** (not JUnit 5):
- `@Test`, `@Before`, `@After`
- `@BeforeClass`, `@AfterClass` for static setup

### Context in Tests

Always create and dispose Context properly:

```java
private Context context;

@Before
public void setUp() {
    context = new Context(ServiceNeeded.class);
}

@After
public void tearDown() {
    context.dispose();
}

@Test
public void testSomething() {
    MyService service = context.service(MyService.class);
    // test code
}
```

## License Headers

Projects typically use simplified BSD or BSD-2-Clause license:

```java
/*
 * #%L
 * [Project Name]
 * %%
 * Copyright (C) [Years] [Copyright Holders]
 * %%
 * [License text...]
 * #L%
 */
```

Use `license-maven-plugin` to validate headers during build.

## Common Services

Frequently used services across the ecosystem:

- **LogService**: Logging (`log.info()`, `log.error()`, etc.)
- **EventService**: Event bus (`publish()`, `@EventHandler`)
- **PluginService**: Plugin discovery and instantiation
- **ModuleService**: Command/module execution
- **ConvertService**: Type conversion framework
- **ScriptService**: Script execution (when scripting is available)

## Event System

```java
// Subscribe to events
@EventHandler
public void onEvent(MyEvent evt) {
    // handle event
}

// Publish events
@Parameter
private EventService eventService;

eventService.publish(new MyEvent());         // Synchronous
eventService.publishLater(new MyEvent());    // Asynchronous
```

## Common Pitfalls

1. **Creating services manually**: Always use Context, never `new MyService()`
2. **Constructor injection**: Use `@Parameter` fields, not constructor args
3. **Forgetting Context.dispose()**: Causes resource leaks in tests
4. **Hardcoded versions in POMs**: Inherit from parent instead
5. **Missing @Plugin annotation**: Plugins won't be discovered
6. **Wrong JUnit version**: Most projects use JUnit 4, not 5
