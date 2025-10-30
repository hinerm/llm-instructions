# ImageJ Swing UI - Copilot Instructions

## Project Overview
ImageJ Swing UI (`imagej-ui-swing`) provides the Java Swing-based user interface for ImageJ, focusing on image display and interactive overlay editing. This is NOT a standalone application—it's a UI plugin component within the larger ImageJ/SciJava ecosystem.

**Key Technologies:**
- Java Swing for UI components
- JHotDraw for interactive drawing/editing of overlays
- SciJava plugin framework for component discovery
- Maven for build management

## Architecture

### Core Design Pattern: Adapter-Based Overlay System
The central architectural pattern bridges ImageJ's `Overlay` domain objects with JHotDraw's `Figure` GUI representations using **bidirectional adapters**:

```
ImageJ Overlay ←→ JHotDrawAdapter ←→ JHotDraw Figure
```

- **Overlays** (`net.imagej.overlay.*`): Domain objects representing ROIs (lines, rectangles, ellipses, etc.)
- **Figures** (JHotDraw library): Swing components for interactive drawing/editing
- **Adapters** (`src/main/java/net/imagej/ui/swing/overlay/*JHotDrawAdapter.java`): Keep overlays and figures synchronized

**Key Service:** `JHotDrawService` discovers and manages all adapters via SciJava's plugin system.

### Display Viewer Architecture
Image display supports two window modes, both extending `AbstractSwingImageDisplayViewer`:

- **SDI (Single Document Interface)**: `SwingSdiImageDisplayViewer` - each image in a `JFrame`
- **MDI (Multiple Document Interface)**: `SwingMdiImageDisplayViewer` - images in `JInternalFrame`s

**Component hierarchy:**
```
DisplayViewer → SwingImageDisplayPanel → JHotDrawImageCanvas
                     ↓                         ↓
              (sliders, color bar)      (JHotDraw DrawingView)
```

`JHotDrawImageCanvas` integrates the JHotDraw drawing canvas into ImageJ's event system.

### Plugin Discovery & Dependency Injection
All components use **SciJava plugin architecture**:

- Mark classes with `@Plugin(type = PluginType.class, priority = ...)`
- Use `@Parameter` for automatic dependency injection of services
- System auto-discovers plugins at runtime by scanning classpath

**Example pattern:**
```java
@Plugin(type = JHotDrawAdapter.class, priority = SwingLineTool.PRIORITY)
public class LineJHotDrawAdapter extends AbstractJHotDrawAdapter<LineOverlay, LineFigure> {
    @Parameter
    private OverlayService overlayService;  // Auto-injected
}
```

## Development Workflows

### Building and Testing
```bash
# Build project
mvn clean install

# Run tests only
mvn test

# Skip tests during build
mvn clean install -DskipTests

# Generate Jacoco coverage report
mvn test jacoco:report
# View at: target/site/jacoco/index.html
```

**Test organization:** Tests live in `src/test/java/net/imagej/ui/swing/updater/` and primarily cover the updater UI components.

### Running in ImageJ
This module doesn't run standalone—it integrates into ImageJ:
1. Build with `mvn clean install` to install to local Maven repo
2. ImageJ application will discover these UI components via SciJava plugin scanning
3. Test UI changes by running full ImageJ application (separate download/build)

### Creating New Overlay Adapters
When adding support for a new overlay type:

1. **Create adapter class** extending `AbstractJHotDrawAdapter<YourOverlay, YourFigure>`
2. **Annotate with `@Plugin`**: `@Plugin(type = JHotDrawAdapter.class, priority = YourTool.PRIORITY)`
3. **Implement key methods:**
   - `supports(Tool tool)` - which tool activates this adapter
   - `supports(Overlay, Figure)` - type matching
   - `createNewOverlay()` - factory method
   - `createDefaultFigure()` - JHotDraw figure creation
   - `updateFigure(OverlayView, Figure)` - sync overlay → figure
   - `updateOverlay(Figure, OverlayView)` - sync figure → overlay
   - `toShape(Figure)` - convert to AWT Shape

4. **Reference examples:** `LineJHotDrawAdapter`, `EllipseJHotDrawAdapter`, `RectangleJHotDrawAdapter`

Priority determines adapter selection when multiple adapters support the same overlay type (higher priority = selected first).

## Project-Specific Conventions

### Package Organization
- `overlay/` - JHotDraw adapters and service
- `viewer/image/` - Image display canvas and panel components
- `sdi/viewer/`, `mdi/viewer/` - Window mode implementations
- `tools/` - Tool plugins (minimal, just priority constants)
- `widget/` - Custom Swing input widgets
- `updater/` - ImageJ Updater GUI (legacy, complex subsystem)
- `commands/` - UI commands (e.g., Overlay Manager)

### Naming Patterns
- Adapters: `*JHotDrawAdapter` (e.g., `LineJHotDrawAdapter`)
- Tools: `Swing*Tool` (e.g., `SwingLineTool`)
- Viewers: `Swing*ImageDisplayViewer`
- Figures (inner/separate classes): `*Figure` (e.g., `LineFigure`, `AngleFigure`)

### Event-Driven Updates
Components communicate via SciJava's event bus (`EventService`):
- Mark methods with `@EventHandler` to subscribe to events
- Publish events with `eventService.publish(new SomeEvent(...))`
- Key events: `FigureCreatedEvent`, `AxisPositionEvent`, `LUTsChangedEvent`, `PanZoomEvent`

**Pattern for event subscription:**
```java
@EventHandler
protected void onEvent(final SomeEvent event) {
    // Handle event
}
```

### Thread Safety & Swing EDT
All Swing UI updates must occur on the Event Dispatch Thread. Use `StaticSwingUtils.invokeOnEDT()` or similar patterns when updating UI from background threads.

## Critical Dependencies

### External Libraries
- **JHotDraw** (`org.jhotdraw:jhotdraw:7.6.0`): Drawing framework for interactive figures
- **MigLayout** (`com.miglayout:miglayout-swing`): Layout manager for complex UIs
- **JFreeChart** (`org.jfree:jfreechart`): Charting (used in color bars)

### ImageJ/SciJava Stack
- `net.imagej:imagej-common` - Core ImageJ services and overlays
- `org.scijava:scijava-common` - Plugin framework, event system, contexts
- `org.scijava:scijava-ui-swing` - Base Swing UI components
- `net.imglib2:imglib2` - Image data structures

Parent POM: `org.scijava:pom-scijava:40.0.0` defines versions centrally.

## Common Pitfalls

1. **Forgetting `@Plugin` annotation**: Adapters/services won't be discovered
2. **Wrong plugin type**: Use `type = JHotDrawAdapter.class` not `type = Plugin.class`
3. **Not calling `setContext()`**: Required before using `@Parameter` injection in manually instantiated objects
4. **Modifying UI off EDT**: Leads to race conditions and visual artifacts
5. **Breaking bidirectional sync**: Both `updateFigure()` and `updateOverlay()` must maintain consistency

## Related Resources
- ImageJ forum: https://forum.image.sc/tag/imagej
- Repository issues: https://github.com/imagej/imagej-ui-swing/issues
- Parent project: https://github.com/imagej/imagej
- JHotDraw docs: http://www.jhotdraw.org/
