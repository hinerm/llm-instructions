# SciJava Script Editor - AI Coding Agent Instructions

## Project Overview

This is a Swing-based script editor and interpreter for SciJava applications, built on the SciJava plugin framework. It provides syntax highlighting, autocompletion, and execution capabilities for multiple scripting languages (Java, Groovy, JavaScript, Python, etc.).

**Key Technologies:**
- SciJava plugin framework (context-based dependency injection)
- RSyntaxTextArea (FifeSoft) for syntax highlighting and language support
- Maven build system
- Java 8+ (targets Java 8 for compatibility)

## Architecture Patterns

### SciJava Plugin System

This project heavily uses SciJava's annotation-based plugin architecture:

```java
@Plugin(type = Command.class, menu = {@Menu(label = "File"), @Menu(label = "New")})
public class ScriptEditor implements Command {
    @Parameter
    private Context context;  // Auto-injected
    
    @Override
    public void run() { /* ... */ }
}
```

**Key patterns:**
- `@Plugin(type = X.class)` - Registers classes as discoverable plugins
- `@Parameter` - Marks fields for context injection
- `context.inject(this)` - Manual injection when needed
- Plugin types include: `Command`, `Service`, `LanguageSupportPlugin`, `SyntaxHighlighter`, `AutoImporter`, `SearchActionFactory`

### Core Components

1. **TextEditor** (`TextEditor.java`) - Main editor window (4000+ lines, monolithic)
   - Manages tabbed interface, menu bar, file operations
   - Coordinates EditorPane, OutputPane, VarsPane
   - Entry point for most editor functionality

2. **EditorPane** (`EditorPane.java`) - Individual text editing pane
   - Extends RSyntaxTextArea
   - Handles syntax highlighting per language
   - Manages bookmarks and error highlighting

3. **InterpreterPane/Window** - REPL interface for interactive scripting

4. **LanguageSupportService** - Manages language-specific features
   - Discovers `LanguageSupportPlugin` instances
   - Provides autocompletion via RSyntaxTextArea's LanguageSupport

### Service Access Pattern

Services are accessed via the Context:

```java
ScriptService scriptService = context.getService(ScriptService.class);
PluginService pluginService = context.getService(PluginService.class);
```

Common services: `ScriptService`, `PluginService`, `LogService`, `ModuleService`, `PrefService`

## Development Workflows

### Building and Testing

```bash
# Standard build
mvn clean install

# Run tests with coverage
mvn test

# Launch Script Editor interactively (with Groovy on classpath)
mvn -Pexec,editor

# Launch Script Interpreter
mvn -Pexec,interp
```

**Note:** The `editor` and `interp` profiles are defined in `pom.xml` and set the main class + test classpath scope.

### Testing Standalone

Test drive classes in `src/test/java`:
- `ScriptEditorTestDrive.java` - Launches editor with Groovy
- `ScriptInterpreterTestDrive.java` - Launches REPL with demo AutoImporter

These use `Main.launch(language)` which creates a Context and TextEditor.

### Adding Language Support

1. Create a `LanguageSupportPlugin` implementation extending RSyntaxTextArea's language support:
   ```java
   @Plugin(type = LanguageSupportPlugin.class)
   public class JavaScriptLanguageSupportPlugin extends JavaScriptLanguageSupport
       implements LanguageSupportPlugin {
       public String getLanguageName() { return "javascript"; }
   }
   ```

2. Optionally add a `SyntaxHighlighter` plugin for custom token makers

### Adding Auto-Imports (Deprecated Pattern)

Implement `AutoImporter` to provide default imports (legacy feature from Fiji days):

```java
@Plugin(type = AutoImporter.class)
public class MyAutoImporter implements AutoImporter {
    public Map<String, List<String>> getDefaultImports() {
        // Return map of package -> class list
    }
}
```

**Note:** Auto-imports are deprecated but maintained for backwards compatibility.

## Project Conventions

### Code Organization

- Main source: `src/main/java/org/scijava/ui/swing/script/`
  - Root: Core editor classes (TextEditor, EditorPane, etc.)
  - `autocompletion/` - ClassUtil for finding documentation URLs
  - `commands/` - Menu command implementations
  - `highliters/` - Custom syntax highlighters (Beanshell, MATLAB, IJ1 macros)
  - `languagesupport/` - Language-specific autocomplete plugins
  - `search/` - Integration with SciJava search framework

### License Headers

All files use BSD 2-clause license with delimited headers (using `#%L` markers). Use the existing header format for new files.

### Dependency Management

Dependencies are managed via `pom-scijava` parent POM. Key dependencies:
- `scijava-common` - Core SciJava framework
- `scijava-search` - Search integration
- `scripting-java` - Java scripting backend
- `rsyntaxtextarea` + `languagesupport` - Editor UI components
- `openai-gpt3-java` - OpenAI integration (experimental)

**Version control:** Use properties in parent POM; avoid hardcoded versions except for `rsyntaxtextarea.version`.

## Common Pitfalls

1. **Context lifecycle:** Always dispose contexts when windows close to prevent resource leaks:
   ```java
   editor.addWindowListener(new WindowAdapter() {
       public void windowClosed(WindowEvent e) {
           context.dispose();
       }
   });
   ```

2. **Plugin discovery:** Plugins are discovered via annotation processing. After adding `@Plugin`, rebuild to regenerate `META-INF/json/org.scijava.plugin.Plugin`.

3. **Test scope dependencies:** Some dependencies like `scripting-groovy` are test-scoped. Use Maven profiles to include them at runtime.

4. **Java version mismatch:** ClassUtil detects Java docs dynamically based on runtime version. Be aware when testing across Java versions.

## Integration Points

### SciJava Search Framework

`ScriptSourceSearchActionFactory` provides "View Source" actions for script modules in the SciJava search UI.

### OpenAI Integration

Experimental OpenAI features in `PromptPane` and `OpenAIOptions`. API key configured via SciJava preferences system (`PrefService`).

### External Documentation

`ClassUtil.findDocumentationForClass()` scrapes javadoc URLs from:
- SciJava javadoc site (https://javadoc.scijava.org/)
- JAR manifest files (pom.xml URLs)
- GitHub/GitLab source repositories
