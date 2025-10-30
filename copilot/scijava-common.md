# SciJava Common: AI Coding Agent Instructions

## Project Overview

**SciJava Common** is the foundational plugin framework for the SciJava ecosystem (ImageJ2, SCIFIO). It provides:
- Dynamic plugin discovery via compile-time annotation processing
- Service-oriented architecture with dependency injection
- Event-driven communication system
- Type conversion framework
- Module/command execution framework with preprocessing/postprocessing pipelines

**Core Philosophy**: Extensibility through plugins. Almost everything (services, converters, commands, tools) is a plugin discovered at runtime.

## Architecture

### 1. Plugin Discovery System (Critical!)

**The chicken-and-egg problem**: SciJava Common provides its own annotation processor while also using it for its own plugins.

**Build process** (`pom.xml`):
```xml
<!-- Annotation processing is DISABLED during compilation -->
<maven-compiler-plugin>
  <compilerArgument>-proc:none</compilerArgument>
</maven-compiler-plugin>

<!-- EclipseHelper is run manually in process-classes phase -->
<exec-maven-plugin>
  <mainClass>org.scijava.annotations.EclipseHelper</mainClass>
</exec-maven-plugin>
```

**Key files**:
- `src/main/java/org/scijava/annotations/AnnotationProcessor.java` - Compile-time processor
- `src/main/java/org/scijava/annotations/EclipseHelper.java` - Runtime fallback for Eclipse incremental builds
- `src/main/resources/META-INF/services/javax.annotation.processing.Processor` - SPI registration

**Plugin index location**: `META-INF/json/` (generated at build time, not in source control)

### 2. Core Components

**Context** (`org.scijava.Context`):
- Application-level IoC container
- Manages service lifecycle and dependency injection
- Services are discovered via `@Plugin(type = Service.class)`
- Use `context.getService(ServiceClass.class)` to retrieve services
- System property `scijava.context.strict` controls error handling for missing services

**Plugin System**:
- `@Plugin(type = SomePlugin.class)` - Marks discoverable plugins
- `priority` attribute controls selection order (see `org.scijava.Priority` constants)
- `PluginInfo` contains metadata without loading classes (performance optimization)
- Common plugin types: `Service`, `Command`, `Converter`, `Tool`, `ScriptLanguage`

**Dependency Injection**:
- `@Parameter` on fields - Auto-injected by Context
- Services inject other services
- `required = false` for optional dependencies
- Works in Services, Commands, and any Context-aware component

**Event System** (`org.scijava.event.EventService`):
- `@EventHandler` on methods to subscribe
- `EventService.publish(event)` - Synchronous (blocks until all handlers complete)
- `EventService.publishLater(event)` - Asynchronous (queues on event dispatch thread)
- Stack-based delivery order with `publish()` can be counter-intuitive

### 3. Module/Command Framework

**Commands** (`org.scijava.command.Command`):
- Executable plugins with inputs/outputs
- `@Parameter` fields define inputs/outputs with `ItemIO.INPUT/OUTPUT/BOTH`
- Wrapped in `CommandModule` for execution
- Extend `ContextCommand` for convenience (not bare `Command`)

**Module execution pipeline**:
1. `ModulePreprocessor` plugins run first (e.g., `InputHarvester` for UI dialogs)
2. `module.run()` executes
3. `ModulePostprocessor` plugins run last (e.g., `DisplayPostprocessor`)

### 4. Type Conversion System

**ConvertService** (`org.scijava.convert.ConvertService`):
- Extensible type conversion via `Converter` plugins
- `convertService.convert(object, TargetClass.class)`
- Converters declare `priority` for selection order
- See `org.scijava.convert` package for examples

## Development Workflows

### Building
```bash
mvn clean install
```

**Common issues**:
- If annotation processing fails, delete `target/` and rebuild
- Eclipse users: EclipseHelper runs automatically at runtime to compensate for incremental build issues

### Testing
- JUnit 4 (not JUnit 5)
- Test pattern: Create `Context` in `@Before`, call `context.dispose()` in `@After`
- Example: `src/test/java/org/scijava/thread/ThreadServiceTest.java`

```java
@Before
public void setUp() {
    context = new Context(ServiceClass.class);
    service = context.getService(ServiceClass.class);
}

@After
public void tearDown() {
    context.dispose();
}
```

### Debugging Plugin Discovery
- Check `target/classes/META-INF/json/` for generated plugin indexes
- Use `org.scijava.log.LogService` for logging (avoid `System.out`)
- Set `force.annotation.index=true` system property to force re-indexing

## Code Conventions

### License Headers
All Java files must have BSD-2-Clause license header:
```java
/*
 * #%L
 * SciJava Common shared library for SciJava software.
 * %%
 * Copyright (C) 2009 - 2025 SciJava developers.
 * %%
 * [Full BSD-2-Clause text]
 * #L%
 */
```

### Plugin Patterns

**Creating a new Service**:
```java
@Plugin(type = Service.class)
public class MyServiceImpl extends AbstractService implements MyService {
    @Parameter
    private LogService logService;  // Injected by Context
    
    // Implementation
}
```

**Creating a Command**:
```java
@Plugin(type = Command.class, menuPath = "Plugins > My Tool")
public class MyCommand extends ContextCommand {
    @Parameter
    private String input;
    
    @Parameter(type = ItemIO.OUTPUT)
    private String output;
    
    @Override
    public void run() {
        output = process(input);
    }
}
```

**Event handling**:
```java
@EventHandler
private void onEvent(SomeEvent event) {
    // Handle event
}
```

### Priority Usage
When multiple plugins of the same type exist:
- `Priority.VERY_HIGH` / `Priority.HIGH` - Override default implementations
- `Priority.NORMAL` (default)
- `Priority.LOW` / `Priority.VERY_LOW` - Fallback implementations
- `Priority.FIRST` / `Priority.LAST` - Edge cases only

## Project Structure

- `src/main/java/org/scijava/` - Source organized by concern:
  - `annotations/` - Annotation processor implementation
  - `plugin/` - Plugin framework core
  - `service/` - Service infrastructure
  - `command/`, `module/` - Command/module execution
  - `event/` - Event bus
  - `convert/` - Type conversion
  - `script/` - Scripting support
  - `util/` - Utilities
- `src/test/java/` - JUnit tests (mirror main structure)
- `src/main/resources/META-INF/services/` - Java SPI registrations
- `target/classes/META-INF/json/` - Generated plugin indexes (not in git)

## Integration Points

- **Parent POM**: `pom-scijava` (version management, build configuration)
- **Downstream projects**: ImageJ2, SCIFIO depend on this
- **Java version**: Targets Java 8 (see `@SupportedSourceVersion(RELEASE_8)`)
- **CI**: GitHub Actions (`.github/workflows/build.yml`) on Ubuntu/Windows/macOS

## Common Pitfalls

1. **Don't manually create plugin instances** - Use `PluginService.createInstance()` or let Context handle it
2. **Annotation processing in IDEs** - IntelliJ IDEA handles it correctly; Eclipse needs `EclipseHelper`
3. **Event delivery order** - Mix of `publish()` and `publishLater()` can cause unexpected ordering
4. **Service dependencies** - Circular dependencies will fail; use `required = false` or lazy initialization
5. **Plugin index stale** - Delete `target/` if plugins aren't discovered after changes

## Key Files to Reference

- `src/main/java/org/scijava/Context.java` - IoC container implementation
- `src/main/java/org/scijava/plugin/PluginService.java` - Plugin discovery/instantiation
- `src/main/java/org/scijava/service/AbstractService.java` - Base class for services
- `src/main/java/org/scijava/command/ContextCommand.java` - Base class for commands
- `pom.xml` - Special annotation processing configuration
