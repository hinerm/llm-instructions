# SciJava Python Scripting - AI Agent Instructions

## Project Overview

This is a **JSR-223 scripting plugin** that bridges CPython (NOT Jython) to the SciJava platform via [scyjava](https://github.com/scijava/scyjava). The plugin enables Python script execution within Java-based SciJava applications (e.g., ImageJ/Fiji).

**Critical Architecture Pattern**: This is a *proxy* implementation. The `PythonScriptEngine` doesn't execute Python directly—it delegates to a `PythonScriptRunner` Function object (registered via `ObjectService`) that's created by the Python side (scyjava) when running in "Python mode".

## Key Components

### 1. Script Engine Delegation Pattern
- **`PythonScriptEngine.eval()`**: Searches `ObjectService` for a `PythonScriptRunner` Function object
- If not found, auto-launches `OptionsPython` plugin to help user enable Python mode
- Actual execution happens Python-side via scyjava; Java just proxies the call
- See lines 83-95 in `PythonScriptEngine.java` for the delegation logic

### 2. Python Environment Management
- **`OptionsPython`**: SciJava plugin (Edit > Options > Python...) managing conda/pip dependencies
- Reads/writes `environment.yml` (default: `config/environment.yml`)
- Stores config in app launcher config file via `Config.load()/save()`
- **Required dependencies**: `pyimagej>=1.7.0` and `appose-python` (git-pinned version)
- Uses [Appose](https://github.com/apposed/appose) library to build conda environments

### 3. Launch Modes
Controlled via `scijava.app.config-file`:
- **JVM mode** (default): `launch-mode=JVM` - Python scripts won't work
- **Python mode**: `launch-mode=PYTHON` - Enables scyjava bridge and `PythonScriptRunner`
- System property: `scijava.python.dir` points to conda environment location

## Development Workflows

### Build & Test
```bash
# Standard Maven build
mvn clean package

# Skip tests/enforcer for faster iteration
mvn -Denforcer.skip -Dmaven.test.skip clean package
```

### Local REPL Testing
Use `repl.sh` to test the plugin locally:
```bash
./repl.sh
```
This script:
1. Builds the JAR and copies dependencies
2. Configures scyjava with project classpath
3. Creates a SciJava Context with Python scripting enabled
4. Launches an interactive Python REPL

**Important**: Requires Python environment with `scyjava` installed. The script expects to run in an environment where `scyjava.enable_python_scripting()` succeeds.

### CI/CD
- GitHub Actions workflow: `.github/workflows/build.yml`
- Uses standard SciJava CI scripts from `scijava/scijava-scripts`
- Build: Java 8 (Zulu distribution)
- Deploys to SciJava Maven repository on tagged releases

## Plugin System Conventions

### SciJava Plugin Annotations
All extensibility points use `@Plugin` annotation:
```java
@Plugin(type = ScriptLanguage.class, name = "Python (pyimagej)", priority = Priority.VERY_LOW)
public class PythonScriptLanguage extends AbstractScriptLanguage { ... }
```

Discovered automatically via SciJava's annotation processing. Priority `VERY_LOW` prevents conflicts with Jython plugin.

### Service Injection Pattern
SciJava services are injected via `@Parameter`:
```java
@Parameter
private LogService logService;

@Parameter(required = false)  // Optional services
private UIService uiService;
```

Context must call `context.inject(this)` in constructor—see `PythonScriptEngine` line 74.

## Common Pitfalls

### 1. Python Mode Not Enabled
**Symptom**: `IllegalStateException: "PythonScriptRunner could not be found"`

**Cause**: Application launched in JVM mode without Python bridge active

**Solution**: Run `OptionsPython` plugin or manually set `launch-mode=PYTHON` in config file

### 2. Environment Rebuild Restrictions
**Cannot rebuild active environment**: `RebuildEnvironment.java` (lines 77-92) blocks rebuilding if `targetDir` matches `scijava.python.dir` system property. User must restart in JVM mode first.

### 3. Path Handling
`OptionsPython.setPythonDir()` (lines 121-143) sanitizes paths for Windows compatibility:
- Preserves drive letter colon (e.g., `C:`)
- Strips other colons and whitespace to prevent config file corruption
- Always use `stringToFile()`/`fileToString()` helpers for path conversion relative to app base directory

## External Dependencies

### Key Libraries
- **scyjava**: Python-Java bridge (referenced, not bundled)
- **appose** (v0.3.0): Conda environment builder
- **scijava-common**: Core SciJava framework
- **rsyntaxtextarea**: Python syntax highlighting (`PythonTokenMaker`)

### System Properties
- `scijava.app.config-file`: Path to app launcher config
- `scijava.python.dir`: Python environment directory (set by OptionsPython)
- `scijava.app.python-env-file`: Override for environment.yml location
- `scijava.app.java-platform`: Platform string for default Python path

## Script Templates

Located in `src/main/resources/script_templates/PyImageJ/`:
- **`CellposeStarDistSegmentation.py`**: Complex example using Cellpose/StarDist
- Demonstrates environment requirements with specific version constraints
- Shows ImageJ integration patterns (ROI conversion, image display)

## Testing Notes

No automated tests exist in `src/test/java/`. Testing requires:
1. Full SciJava application context
2. Python environment with scyjava/pyimagej
3. Manual REPL testing via `repl.sh`

When adding functionality, verify with both JVM and Python launch modes.
