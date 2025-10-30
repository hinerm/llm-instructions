# ImageJ Scripting Codebase Guide

## Project Overview

This repository contains **example scripts in multiple languages** (Python/Jython, Groovy, Scala) that demonstrate ImageJ/SciJava APIs. All scripts in `src/main/resources/script_templates/` appear in ImageJ's Script Editor under the Templates menu.

**Key distinction**: This is NOT a typical library project. It's a collection of educational script templates with automated tests to ensure they remain functional as ImageJ components evolve.

## Architecture & Dependencies

### SciJava Plugin Framework
- Built on **SciJava plugin framework** - scripts use dependency injection via `#@` parameter annotations
- Parent POM: `org.scijava:pom-scijava` manages all transitive dependencies
- Core services: `OpService`, `DatasetIOService`, `UIService`, `ScriptService`, `LogService`

### Script Parameter Injection Pattern
Scripts use SciJava's script parameter syntax at the top of files:
```python
#@ OpService ops
#@ ImgPlus inputData
#@ Double sigma
#@OUTPUT ImgPlus filtered
```
This syntax works across **all supported languages** (Python, Groovy, Scala, JavaScript, etc.) - the `#@` prefix is universal.

### Multi-Language Support
Dependencies include scripting engines for: Groovy, Jython, JRuby, JavaScript, Scala, Clojure, Renjin (R), BeanShell. Each script demonstrates language-specific ImageJ API usage patterns.

## Testing Conventions

### Test Structure Philosophy
Tests validate that **scripts execute without errors** and produce non-null outputs. They're intentionally simple because the goal is runtime validation, not comprehensive behavioral testing.

### Base Test Pattern
All test classes extend `AbstractScriptTest`:
```java
public class MyScriptTest extends AbstractScriptTest {
    @Parameter
    private DatasetIOService datasetIOService;
    
    @Test
    public void testMyScript() throws Exception {
        Map<String, Object> parameters = new HashMap<>();
        parameters.put("input", datasetIOService.open("fake-dataset-path"));
        
        File scriptFile = new File(getClass().getResource(
            "/script_templates/Category/Script_Name.py").toURI());
        ScriptModule m = scriptService.run(scriptFile, true, parameters).get();
        
        Object output = m.getOutput("outputName");
        // Basic null/size assertions
    }
}
```

### Fake Dataset Generation
Tests use SCIFIO's `.fake` format to generate test data without real files:
- Format: `"8bit-signed&pixelType=int8&axes=X,Y,Z&lengths=100,100,50.fake"`
- Supports various pixel types and dimensionalities
- See `DatasetIOService.open()` usage in `TutorialsScriptTest.java`

### Context Setup
Tests create a SciJava `Context` with required services. Override `createContext()` in `AbstractScriptTest` to customize available services for specific test needs.

## Development Workflow

### Building
Standard Maven build:
```bash
mvn clean install
```

Uses Java 8 and inherits build configuration from `pom-scijava` parent.

### CI/CD
GitHub Actions builds on `master` branch and tags. Uses shared SciJava CI scripts:
- `.github/setup.sh` → downloads `ci-setup-github-actions.sh`
- `.github/build.sh` → downloads `ci-build.sh`

### Adding New Script Templates
1. Create script in `src/main/resources/script_templates/<Category>/`
2. Use `#@` annotations for parameter injection
3. Add corresponding test in `src/test/java/net/imagej/scripting/`
4. Test should verify script executes and produces expected output

Example test categories by script type:
- `TutorialsScriptTest` - Tutorial scripts
- `DeconvolutionScriptTest` - Deconvolution examples  
- `ImageJ2ScriptTest` - ImageJ2 API demonstrations

## Project-Specific Patterns

### ImgLib2 Integration
Scripts heavily use ImgLib2 types (`ImgPlus`, `RandomAccess`, `RealType`). The test helper methods `assertSamplesEqual()` and `assertConstant()` iterate over `IterableInterval<T>` to validate pixel values.

### License Headers
Java files use delimited license headers (`/*- #%L ... #L% */`). Script templates in `src/main/resources/script_templates/` are **excluded** from license requirements (see `pom.xml` `license.excludes`).

### Resource Paths in Tests
Access script files via classpath resources with leading `/`:
```java
"/script_templates/Tutorials/My_Script.py"
```

### ImageJ Ops Framework
Most scripts demonstrate the Ops framework - type-safe, reusable image processing operations accessed via `OpService`. Common pattern:
```python
filtered = ops.filter().gauss(input, sigma)
thresholded = ops.threshold().otsu(image)
```

## Key Files

- `src/test/java/net/imagej/scripting/AbstractScriptTest.java` - Base test class with helper methods
- `src/test/java/net/imagej/scripting/ScriptTest.java` - Test interface defining lifecycle
- `pom.xml` - Inherits from `pom-scijava`, defines scripting engine dependencies
