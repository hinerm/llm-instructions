# ImageJ Tutorials Project - AI Coding Assistant Instructions

## Project Overview

This is the **ImageJ tutorials repository** containing educational examples for ImageJ2 and SciJava framework development. The project is split into two main sections:
- **Java tutorials** (`java/`): Maven-based example projects demonstrating ImageJ2/SciJava APIs
- **Jupyter notebooks** (`notebooks/`): Interactive tutorials using Groovy/Python kernels

All code is released under the **Unlicense** (public domain).

## Architecture & Key Concepts

### SciJava Plugin System
The core architectural pattern is the **SciJava plugin framework** with dependency injection:

- **@Plugin annotation**: Declares plugin types (`Command`, `Service`, `Op`, etc.)
- **@Parameter annotation**: Auto-injected fields for services, inputs, and outputs
- **ImageJ gateway**: Entry point (`new ImageJ()`) providing access to all services

Example pattern from `howto/commands/simple/HelloWorld.java`:
```java
@Plugin(type = Command.class, menuPath = "Help>Hello, World!")
public class HelloWorld implements Command {
    @Parameter
    private String name;  // Auto-populated from UI
    
    @Parameter(type = ItemIO.OUTPUT)
    private String greeting;  // Output parameter
    
    @Override
    public void run() {
        greeting = "Hello, " + name + "!";
    }
}
```

### Project Structure Convention
- **`java/howtos/`**: Consolidated tutorials organized by topic (`commands/`, `ops/`, `images/`, `ui/`, etc.)
- Each HowTo class has static methods demonstrating specific solutions
- All runnable classes include a `main()` method for IDE execution
- Use `Template.java` as starting point for new tutorials

### Multi-Module Maven Setup
- Root aggregator POM (`pom.xml`) extends `pom-scijava` parent (currently v34.1.0)
- Java 8 compatibility required
- Child modules: `howtos`, `custom-preprocessor-plugin`, `execute-commands`, `ij2-image-plus`, `listen-to-events`, `swing-example`

## Development Workflow

### Building & Running
```bash
# Build entire project
mvn clean install

# Run individual tutorial from IDE
# Just execute the main() method in any Java file

# Run from command line
mvn exec:java -pl java/howtos -Dexec.mainClass="howto.commands.simple.HelloWorld"
```

### Testing Changes
**Important**: All migrated code is manually tested per `java/howtos/migration-notes.md`
- Test each class via its `main()` method
- Note UI framework used (AWT/Swing)
- Document any rendering bugs (known legacy ImageJ1 display issues exist)
- Mark migration status in tracking table

### Jupyter Notebooks
Setup local environment:
```bash
conda env create -f environment.yml
conda activate scijava
jupyter notebook
```
- Notebooks use **BeakerX** Groovy kernel (JVM-based)
- Python notebooks use **pyimagej** package
- Entry point: `notebooks/ImageJ-Tutorials-and-Demo.ipynb`

## Code Conventions

### ImageJ2 Plugin Development
1. **Service injection**: Use `@Parameter` for services (LogService, OpService, DatasetService, etc.)
2. **Headless support**: Add `headless = true` to @Plugin when appropriate
3. **Input/Output**: Mark outputs with `@Parameter(type = ItemIO.OUTPUT)`
4. **Validation**: Use custom validators via `@Parameter(validater = "methodName")`
5. **Menu paths**: Format as `"Category>Subcategory>Command Name"`

### HowTo Guidelines (from `java/howtos/src/main/java/howto/README.md`)
- One class per question/topic
- Keep solutions simple and minimal
- Each solution = one static method
- Use comments to explain code steps
- Include working `main()` method for testing

### Naming Patterns
- Commands: `VerbNoun.java` (e.g., `OpenImage.java`, `CreateTable.java`)
- Ops: `NameOp.java` suffix (e.g., `RampOp.java`, `RandomBlobsOp.java`)
- Services: `NameService.java` suffix (e.g., `AnimalService.java`)

## Common Integration Points

### ImageJ Services (accessed via gateway)
```java
ImageJ ij = new ImageJ();
ij.op()         // OpService - image operations
ij.log()        // LogService - logging
ij.ui()         // UIService - display management
ij.command()    // CommandService - run commands programmatically
ij.plugin()     // PluginService - plugin discovery
ij.dataset()    // DatasetService - image data management
```

### UI Framework Considerations
- **AWT UI**: Default, but has known rendering bugs with some images
- **Swing UI**: Request via `ij.ui().showUI("swing")` for better event handling
- **Headless mode**: Set `headless = true` in @Plugin for non-GUI operations

### ImageJ Ops Framework
Custom ops extend `AbstractOp` and use `@Plugin(type = Op.class, name = "opname")`:
```java
@Plugin(type = Op.class, name = "narf")
public static class Narf extends AbstractOp {
    @Parameter private String input;
    @Parameter(type = ItemIO.OUTPUT) private String output;
    
    @Override
    public void run() {
        output = "Egads! " + input.toUpperCase();
    }
}
// Usage: ij.op().run("narf", "input")
```

## Known Issues & Workarounds
- **Legacy display bug**: Some images render incorrectly in AWT UI (documented in migration-notes.md)
- **TrollPreprocessor**: Triggers for every command - intentionally annoying demo, not for migration
- **DeconvolutionDialog**: Swing buttons broken, do not migrate yet
- **Table display**: May throw `io.scif` exceptions on older pom-scijava versions

## External Resources
- ImageJ wiki: https://imagej.net/develop
- Image.sc Forum: https://forum.image.sc/tags/imagej
- Maven repo: https://maven.scijava.org/content/groups/public
- Plugin development guide: https://imagej.net/develop/plugins

## CI/CD
- GitHub Actions workflow in `.github/workflows/build-main.yml`
- Uses Java 8 (Zulu distribution)
- Runs `ci-build.sh` from scijava-scripts
- Maven repository: SciJava public
