# ij1-patcher AI Coding Instructions

## Project Purpose
This project performs runtime bytecode manipulation of ImageJ 1.x using Javassist to inject extension points and enable headless operation. It creates isolated ImageJ instances via custom class loaders.

## Core Architecture

### Bytecode Patching Pipeline
1. **CodeHacker** (`CodeHacker.java`) - Low-level Javassist wrapper for bytecode manipulation. Modifies classes before they're loaded into the JVM.
2. **LegacyInjector** (`LegacyInjector.java`) - Orchestrates the patching process. Uses callback pattern (`before` and `after` lists) to allow configuration before/after patches are applied.
3. **LegacyExtensions** (`LegacyExtensions.java`) - Applies specific runtime patches for backwards compatibility (e.g., restoring deprecated methods).

### Hook System
- **LegacyHooks** (abstract base class) - Extension point interface injected into `ij.IJ._hooks` field. Must NOT reference any ImageJ classes (shared across class loaders).
- **EssentialLegacyHooks** (concrete implementation) - Default hooks implementation. Instantiated automatically by patched ImageJ unless custom hooks are installed.
- Hooks are called from patched ImageJ code at strategic points (quit(), showProgress(), etc.).

### Class Loader Isolation
- **LegacyClassLoader** - Custom URLClassLoader that isolates ImageJ instances. Shares only `LegacyHooks` class definition with parent loader to enable communication.
- **LegacyEnvironment** - High-level API for creating encapsulated ImageJ instances. Example: `new LegacyEnvironment(null, true)` creates headless instance.

### Headless Support
- **LegacyHeadless** - Replaces `GenericDialog` superclass with fake AWT-free version. Only works for "well-behaved" plugins that don't directly manipulate GUI.
- **HeadlessGenericDialog** - Stub dialog that doesn't require graphical environment.

### Java Agent
- **JavaAgent** - ClassFileTransformer for applying patches at JVM startup via `-javaagent:ij1-patcher.jar`. Supports modes: `init`, `debug`, `noop`.

## Critical Conventions

### Adding New Extension Points
1. Add method to END of `LegacyHooks` with default implementation (forward compatibility).
2. Add patching logic to `LegacyExtensions.injectHooks()`.
3. Insert hook calls via `CodeHacker.insertAtTopOfMethod()` or `insertAtBottomOfMethod()`.

### Callback Configuration Pattern
Configure `LegacyEnvironment` by adding callbacks to `LegacyInjector`:
```java
injector.after.add(new Callback() {
    @Override public void call(CodeHacker hacker) {
        // Custom patches here
    }
});
```

### Version Compatibility
- Use `LegacyInjector.isImageJ1VersionAtLeast(hacker, "1.53c")` to conditionally apply patches.
- Access constants without loading classes: `hacker.getConstant("ij.ImageJ", "VERSION")`.

### Sharing State Across Class Loaders
- `LegacyHooks` is the ONLY class shared between loaders (defined in `LegacyClassLoader.sharedClasses`).
- Cannot pass ImageJ objects (like `ImagePlus`) directly between loaders - use reflection or macros instead.
- `EssentialLegacyHooks` and `HeadlessGenericDialog` are known but NOT shared (in `knownClasses` but not `sharedClasses`).

## Testing Patterns

### Test Utilities (`TestUtils.java`)
- `getTestEnvironment()` - Creates headless LegacyEnvironment for testing.
- `construct(loader, className, params...)` - Instantiate classes via reflection across class loaders.
- `invoke(object, methodName, params...)` - Call methods reflectively.
- `makeJar(file, classNames...)` - Bundle test plugins into JAR with `plugins.config`.

### Integration Tests
- Tests that patch at class load time: Extend with `CodeHackerIT.java` pattern (no `-javaagent`).
- Tests using Java agent: Use `@failsafe` executions with `-javaagent:${ij1-patcher.jar}=MODE` (see `pom.xml` executions: `code-hacker`, `debug`, `pre-init`).
- Always call `LegacyInjector.preinit()` in static initializer for tests requiring early patching.

### Thread Context Requirements
ImageJ 1.x checks thread name for macro options: Thread name must start with `"Run$_"` for `Macro.getOptions()` to work.

## Build & Development

### Maven Lifecycle
- Standard build: `mvn clean install`
- Run integration tests: `mvn verify` (automatically runs different `-javaagent` modes)
- See `pom.xml` for multiple `maven-failsafe-plugin` executions testing different agent modes.

### Debugging Bytecode Patches
1. Use `JavaAgent` in debug mode: `-javaagent:ij1-patcher.jar=debug`
2. Set system property: `-Dij1-patcher.mode=debug`
3. Check `CodeHacker` methods for patch introspection: `hacker.hasField()`, `hacker.hasMethod()`.

### Custom Initializers
Override default initializer by setting system property:
```
-Dij1.patcher.initializer=com.example.MyInitializer
```
Class must implement `Runnable` and be loadable via ImageJ's PluginClassLoader.

## Common Pitfalls

- **Don't** reference ImageJ classes in `LegacyHooks` - breaks class loader isolation.
- **Don't** assume patches apply at construction - use callbacks for configuration before `injectHooks()`.
- **Don't** modify old hook methods - only add new ones at the end (binary compatibility).
- **Remember** headless mode fails for plugins using AWT directly (not via `GenericDialog`).
- **Use** `writeJar()` to persist patched classes to disk for distribution or debugging.
