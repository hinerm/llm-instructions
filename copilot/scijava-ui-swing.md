# SciJava UI Swing - AI Agent Instructions

## Project Overview
This is a **Java Swing UI component library** for the SciJava framework, providing user interface implementations using Java Swing. The library integrates with SciJava's plugin architecture to deliver UI widgets, viewers, dialogs, and window management for scientific applications.

## Architecture Fundamentals

### SciJava Plugin System
- **Plugin Discovery**: All components use `@Plugin` annotations (e.g., `@Plugin(type = Service.class)`, `@Plugin(type = InputWidget.class)`)
- **Dependency Injection**: Services and dependencies use `@Parameter` annotation for automatic injection
- **Plugin Index**: Plugins are indexed at compile time in `target/classes/META-INF/json/org.scijava.plugin.Plugin`
- **Context Management**: All components operate within a SciJava `Context` which manages plugin lifecycle and service discovery

Example plugin pattern:
```java
@Plugin(type = InputWidget.class)
public class SwingNumberWidget extends SwingInputWidget<Number> {
    @Parameter
    private ThreadService threadService;
    
    @Parameter
    private ModuleService moduleService;
}
```

### UI Architecture Patterns

**Two UI Modes:**
- **SDI** (Single Document Interface): `SwingSDIUI` - default, higher priority
- **MDI** (Multiple Document Interface): `SwingMdiUI` - uses internal frames with `JMDIDesktopPane`

**Core Component Hierarchy:**
```
AbstractSwingUI (base for both SDI/MDI)
├── SwingApplicationFrame (main window)
├── SwingToolBar (tool buttons)
├── SwingStatusBar (bottom status)
└── SwingConsolePane (console/logging UI)
```

### Widget System
All input widgets extend `SwingInputWidget<T>` which provides:
- **MigLayout**: All widgets use MigLayout with pattern `new MigLayout("fillx,ins 3 0 3 0", "[fill,grow|pref]")`
- **Tool Tips**: Set via `setToolTip(component)` using model description
- **Type Safety**: Generic type `<T>` matches the input value type

Available widgets in `src/main/java/org/scijava/ui/swing/widget/`:
- `SwingNumberWidget` - numbers with spinner/slider/scrollbar
- `SwingColorWidget`, `SwingDateWidget`, `SwingFileWidget`, `SwingTextWidget`, etc.

### Event Dispatchers
Event propagation uses three AWT dispatcher types (from `scijava-ui-awt`):
- `AWTInputEventDispatcher` - keyboard and mouse events
- `AWTWindowEventDispatcher` - window lifecycle events  
- `AWTDropTargetEventDispatcher` - drag-and-drop events

Register dispatchers on display windows:
```java
new AWTInputEventDispatcher(display).register(displayWindow, true, false);
new AWTWindowEventDispatcher(display).register(displayWindow);
new AWTDropTargetEventDispatcher(display, eventService);
```

## Build & Development

### Standard Maven Commands
```bash
# Build the project
mvn clean install

# Skip tests during build
mvn clean install -DskipTests

# Run tests only
mvn test

# Check for compilation issues
mvn compile
```

### Java Version
- **Target**: Java 8 (see GitHub Actions workflow)
- Distribution: Zulu OpenJDK

### Testing
- **Entry Point**: `src/test/java/org/scijava/ui/swing/Main.java` - launches UI for manual testing
- Run with: `new Context().service(UIService.class).showUI(SwingUI.NAME)`

### Dependencies
Key external libraries:
- **MigLayout** (`miglayout-swing`) - layout manager used extensively
- **JFreeChart** - plotting components in `plot/` package
- **FlatLaf** (`com.formdev:flatlaf`) - modern look and feel themes
- **SciJava Common** - core framework (plugin system, events, services)

## Code Conventions

### Look & Feel Management
- Service: `SwingLookAndFeelService` handles L&F initialization
- FlatLaf themes: `FlatLightLaf`, `FlatDarkLaf`, `FlatIntelliJLaf`, `FlatDarculaLaf`
- Must call `lafService.initLookAndFeel()` before creating Swing components

### Menu System
Menu creation uses shadow menu pattern:
- `SwingJMenuBarCreator` - creates JMenuBar from ShadowMenu
- `SwingJPopupMenuCreator` - creates context menus
- `AbstractSwingMenuCreator` - base menu creation logic

### Console & Logging
`SwingConsolePane` provides two tabs:
- **Console tab**: `ConsolePanel` for general output
- **Log tab**: `LoggingPanel` for structured logging with filtering
- Both use MigLayout with `"insets 0"` pattern

### Threading Considerations
- **EDT Safety**: Use `threadService.invoke()` for Swing operations (see `AbstractSwingUI.chooseFile()`)
- **JFileChooser**: Must run on EDT to avoid deadlocks (especially macOS)

## Common Patterns

### Creating a New Widget
1. Extend `SwingInputWidget<YourType>`
2. Add `@Plugin(type = InputWidget.class)` annotation
3. Implement `getValue()` and widget-specific interface
4. Use MigLayout for component layout
5. Inject required services with `@Parameter`

### Adding a Command
```java
@Plugin(type = Command.class, menuPath = "Plugins>Your Menu>Command Name")
public class YourCommand implements Command {
    @Parameter
    private UIService uiService;
    
    @Override
    public void run() {
        // Implementation
    }
}
```

### Display Viewers
Implement `DisplayViewer` interface with `@Plugin(type = DisplayViewer.class)`:
- Examples: `SwingPlotDisplayViewer`, `SwingTableDisplayViewer`, `SwingTextDisplayViewer`
- Located in `src/main/java/org/scijava/ui/swing/viewer/`

## Key Files Reference

- `AbstractSwingUI.java` - Base UI implementation with core setup
- `SwingInputWidget.java` - Base class for all input widgets
- `SwingNumberWidget.java` - Complex widget example with multiple input modes
- `SwingSDIUI.java` / `SwingMdiUI.java` - The two UI mode implementations
- `SwingLookAndFeelService.java` - Theme management
- `pom.xml` - Maven build configuration, parent POM is `pom-scijava:38.0.1`

## Notes
- License: BSD-2-Clause (Simplified BSD)
- Organization: SciJava (https://scijava.org/)
- CI: GitHub Actions (`.github/workflows/build-main.yml`)
- Uses SciJava parent POM which provides common build configuration
