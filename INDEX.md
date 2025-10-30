# Instruction File Index

This index shows the relationships between instruction files and when to use them.

## Quick Selection Guide

### Working on SciJava Projects
**Start with**: `scijava-foundation.md` (shared concepts for all projects)

### By Task Type

#### Image Processing Development
- **Core library work**: `imglib2.md` (data structures), `imagej-common.md` (ImageJ2 data model)
- **Algorithm development**: `imagej-ops.md` (ops framework)
- **Format I/O**: `scifio.md` (image file formats)

#### Application Development
- **ImageJ2 app**: `imagej2.md` (gateway), `imagej-common.md` (data model)
- **Fiji distribution**: `fiji.md` (distribution), `imagej2.md` (core)
- **Original ImageJ compatibility**: `imagej-legacy.md` (bridge layer), `imagej1.md` (IJ1 specifics)

#### Scripting & Editor
- **Script editor development**: `scijava-script-editor.md` (editor UI), `scijava-common.md` (plugin system)
- **Script examples/templates**: `imagej-scripting.md` (example patterns)
- **Python scripting (Jython)**: `scijava-scripting-python.md` (JSR-223 bridge)
- **Python wrapper (CPython)**: `pyimagej.md` (PyImageJ library)

#### User Interface
- **Swing UI components**: `imagej-ui-swing.md`, `scijava-ui-swing.md`
- **App launcher**: `scijava-app-launcher.md`

#### Special Features
- **Update system**: `imagej-updater.md`
- **ImageJ1 patching**: `ij1-patcher.md`
- **Tutorial examples**: `imagej-tutorials.md`

#### Non-ImageJ Projects
- **LLM application development**: `langchain4j-core-module.md`

## File Dependency Map

### Foundation Layer
```
scijava-foundation.md (shared concepts)
└── scijava-common.md (core framework)
    ├── imagej-common.md (ImageJ data model)
    │   ├── imagej2.md (application gateway)
    │   ├── imagej-ops.md (algorithm framework)
    │   ├── imagej-legacy.md (IJ1 bridge)
    │   └── imagej-ui-swing.md (Swing UI)
    ├── scijava-script-editor.md (editor)
    ├── scijava-scripting-python.md (Python bridge)
    ├── scijava-ui-swing.md (Swing components)
    ├── scijava-app-launcher.md (launcher)
    └── scifio.md (I/O framework)
```

### Image Data Layer
```
imglib2.md (core data structures)
└── imagej-common.md (ImageJ wrapper)
    ├── All ImageJ libraries depend on this
    └── pyimagej.md (Python wrapper uses this)
```

### Application Layer
```
imagej2.md (core application)
└── fiji.md (extended distribution)

imagej1.md (original ImageJ)
└── imagej-legacy.md (compatibility bridge)
    └── ij1-patcher.md (bytecode modification)
```

### Scripting Layer
```
scijava-common.md (script service)
├── imagej-scripting.md (example scripts)
├── scijava-scripting-python.md (Jython via JSR-223)
├── scijava-script-editor.md (editor GUI)
└── pyimagej.md (CPython via JPype)
```

## Recommended File Combinations

### Developing a Script Editor Plugin
1. `scijava-foundation.md` - Plugin system basics
2. `scijava-script-editor.md` - Editor architecture
3. `scijava-common.md` - Service details (if needed)

### Building ImageJ2 Algorithms
1. `scijava-foundation.md` - Plugin system basics
2. `imglib2.md` - Data structures
3. `imagej-common.md` - ImageJ data model
4. `imagej-ops.md` - Ops framework (if using ops)

### Creating Format Readers
1. `scijava-foundation.md` - Plugin system basics
2. `imglib2.md` - Image data structures
3. `scifio.md` - Format architecture

### Working on Fiji Distribution
1. `scijava-foundation.md` - Plugin system basics
2. `imagej2.md` - Core application
3. `fiji.md` - Distribution specifics

### Python Integration Work
- **Jython (in-JVM)**: `scijava-scripting-python.md`, `scijava-common.md`
- **CPython (external)**: `pyimagej.md`, `imagej-common.md`, `imglib2.md`

### ImageJ1 Compatibility
1. `imagej1.md` - Original ImageJ
2. `imagej-legacy.md` - Bridge architecture
3. `ij1-patcher.md` - Bytecode patching (if modifying patcher)

## Project Characteristics

### Libraries vs Applications
**Libraries** (reusable components):
- imglib2, imagej-common, imagej-ops, scifio
- scijava-common, scijava-script-editor
- Focus on APIs and extension points

**Applications** (end-user):
- imagej2, fiji
- Focus on dependency aggregation and entry points

### Plugin Types by Project
- **Services**: scijava-common, imagej-common, scifio
- **Commands**: imagej-ops, imagej-legacy, script-editor
- **Formats**: scifio
- **Languages**: scijava-scripting-python
- **UI Components**: imagej-ui-swing, scijava-ui-swing

## Completeness Status

✅ **Complete** - Comprehensive coverage:
- scijava-common, imagej-common, imglib2
- imagej2, fiji, scifio
- scijava-script-editor, pyimagej
- langchain4j-core-module

✅ **Good** - Covers main workflows:
- imagej-legacy, imagej-ops
- scijava-scripting-python, imagej-scripting
- imagej-updater, ij1-patcher

⚠️ **Partial** - May need expansion:
- imagej-ui-swing, scijava-ui-swing
- scijava-app-launcher
- imagej-tutorials, imagej1

## Generation Notes

All files in `copilot/` were generated using GitHub Copilot by analyzing the respective project repositories. They reflect project state as of late 2024 / early 2025.

**Maintenance**: Update these files when projects undergo major architectural changes or version bumps.
