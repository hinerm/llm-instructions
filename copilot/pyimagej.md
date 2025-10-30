# PyImageJ AI Coding Guidelines

> **Related files**: For understanding the Java side, see `imagej2.md` (application), `imagej-common.md` (data model), and `imglib2.md` (image data structures). For Jython (in-JVM Python), see `scijava-scripting-python.md`.

## Project Overview

PyImageJ is a Python wrapper for ImageJ2/ImageJ that bridges the Java and Python ecosystems. It uses **JPype** to spawn a JVM, **scyjava** for Java-Python interop, and **imglyb** for zero-copy image sharing via shared memory.

**Key architectural principle**: PyImageJ is fundamentally a **bridge library** - it does not reimplement ImageJ functionality in Python, but rather provides Pythonic access to Java-based ImageJ APIs.

## Critical Dependencies & Their Roles

- **scyjava**: Java class importing and JVM configuration (use `scyjava.jimport()` for Java classes)
- **JPype**: Low-level JVM bridge with class customization mechanism (see `@JImplementationFor` decorators)
- **imglyb**: Zero-copy NumPy↔ImgLib2 conversion via shared memory
- **xarray**: Primary Python data structure for images (labeled multi-dimensional arrays)
- **jgo**: Maven artifact resolution and JAR dependency management

## Initialization Patterns

PyImageJ initialization is **two-phase** and **configuration order matters**:

```python
import imagej
import scyjava

# Phase 1: JVM configuration (MUST happen before init)
scyjava.config.add_option('-Xmx6g')  # Can only set JVM options before JVM starts

# Phase 2: Gateway initialization
ij = imagej.init()  # Downloads ImageJ2 if needed, starts JVM
```

**Common initialization modes**:
- `imagej.init()` - Latest ImageJ2, headless mode (default)
- `imagej.init('2.14.0')` - Specific version (reproducible)
- `imagej.init('sc.fiji:fiji')` - Fiji with plugins
- `imagej.init('/path/to/Fiji.app')` - Local installation
- `imagej.init(mode='gui')` - GUI mode (blocking)
- `imagej.init(mode='interactive')` - GUI available but non-blocking
- `imagej.init(add_legacy=False)` - Pure ImageJ2 without original ImageJ

## Core Data Conversion API

The `ij.py` gateway provides conversion utilities. **Always use these instead of manual conversion**:

```python
# Java → Python
xarr = ij.py.from_java(dataset)      # Dataset/ImgPlus/RAI → xarray
xarr = ij.py.from_java(imageplus)    # ImagePlus → xarray

# Python → Java  
dataset = ij.py.to_java(np_array)    # numpy/xarray → Dataset (default)
img = ij.py.to_img(np_array)         # numpy/xarray → ImgLib2 Img
imageplus = ij.py.to_imageplus(data) # any → ImagePlus

# Cross-Java conversions
imageplus = ij.py.to_imageplus(dataset)
dataset = ij.py.to_dataset(imageplus)
```

**Dimension ordering**: 
- Java ImageJ2 (Dataset/ImgPlus): Uses **XYZCT** axis labels
- Python (xarray): Uses **TZYXC** dimension order (numpy standard)
- Conversions handle permutation automatically

## Working with Java Classes

Use `scyjava.jimport()` for all Java class imports (NOT `jpype.JClass`):

```python
from scyjava import jimport

# Import Java classes
Views = jimport('net.imglib2.view.Views')
Axes = jimport('net.imagej.axis.Axes')
ArrayList = jimport('java.util.ArrayList')

# Access static members
x_axis = Axes.X
```

## Running ImageJ Operations

Three primary execution pathways:

1. **ImageJ2 Ops Framework** (preferred for pure ImageJ2):
```python
result = ij.op().filter().gauss(image, sigma=2.0)  # Returns new image
```

2. **Original ImageJ Macros** (for legacy workflows):
```python
macro = """
#@ ImagePlus imp
#@output ImagePlus result
run("Gaussian Blur...", "sigma=2.0");
"""
result = ij.py.run_macro(macro, {"imp": imageplus})
```

3. **Plugins** (for GUI-based operations):
```python
ij.py.run_plugin("Gaussian Blur...", {"sigma": 2.0}, imp=imageplus)
```

**⚠️ CRITICAL**: Many operations modify images **in-place**. Always duplicate first:
```python
original = ij.IJ.openImage(url)
copy = original.duplicate()  # Preserve original
ij.py.run_plugin("Process Operation", args, imp=copy)
```

## Testing Conventions

Tests use **pytest** with a shared `ij` fixture (see `conftest.py`):

```python
def test_feature(ij):
    """Tests receive initialized ImageJ gateway"""
    dataset = ij.io().open(url)
    assert dataset is not None
```

**Test execution**:
- `make test` or `bin/test.sh` - Runs full test matrix (multiple ImageJ versions, local Fiji)
- Tests run in **headless mode** by default
- Use `pytest --ij=sc.fiji:fiji` to test specific endpoints
- Tests are parameterized: ImageJ2+legacy, pure ImageJ2, Fiji variants

## Development Workflows

**Package management**: Uses **uv** (modern Python package manager):
```bash
uv run python        # Run Python with project dependencies
make test            # Run tests (uses uv internally)
make lint            # Run ruff formatter/linter
make docs            # Build Sphinx documentation
```

**Dependency groups** (in `pyproject.toml`):
- `dev` - Testing and linting tools (pytest, ruff, pre-commit)
- `docs` - Sphinx documentation building
- `matplotlib` - Optional display backend
- `notebooks` - Jupyter and scikit-image for examples

## Architecture Patterns

### JPype Class Customization
PyImageJ extends Java classes with Python methods via `@JImplementationFor`:

```python
@JImplementationFor("net.imagej.ImageJ")
class GatewayAddons:
    @property
    def py(self):
        """Add ij.py namespace with Python utilities"""
        return ImageJPython(self)
```

This pattern adds the `.py` attribute to the Java `ImageJ` class, providing:
- `ij.py.from_java()` / `ij.py.to_java()` conversions
- `ij.py.show()` for matplotlib display  
- `ij.py.run_macro()` / `ij.py.run_plugin()` / `ij.py.run_script()` execution

### Module Organization
- `__init__.py` - Main gateway, initialization, JPype customizations (~1800 lines)
- `convert.py` - Type conversion functions (Java↔Python, ~700 lines)
- `dims.py` - Dimension manipulation and axis handling (~450 lines)
- `images.py` - Image type checking utilities
- `stack.py` - Stack/slice operations
- `doctor.py` - Environment diagnostics (`imagej.doctor.checkup()`)
- `_java.py` - Internal Java utilities (NOT for external use)

## Headless vs GUI Modes

**Headless limitations**: Original ImageJ GUI operations may fail (e.g., `RoiManager`, `WindowManager`).

**Workaround for headless GUI needs**: Use **Xvfb** (virtual frame buffer):
```bash
xvfb-run -a python script.py
```
Initialize with `mode='interactive'` (not `headless`) when using Xvfb.

## Common Pitfalls

1. **JVM configuration after init**: ❌ `scyjava.config` MUST be called before `imagej.init()`
2. **Mixing conversion APIs**: ❌ Use `ij.py.from_java()`, not raw `ij.convert()` (handles dimension ordering)
3. **In-place modifications**: ❌ Always duplicate images before destructive operations
4. **Headless mode with GUI operations**: ❌ Original ImageJ GUI methods fail headless - use Xvfb or `mode='interactive'`
5. **Fabricating image URLs**: ❌ Use placeholders with comments instead of fake URLs

## LLM-Specific Resources

The `doc/llms/` directory contains comprehensive AI coding rulesets:
- `rulesets/pyimagej_core.md` - Core PyImageJ API patterns
- `rulesets/environments/env_*.md` - Environment-specific rules (Colab, headless, etc.)
- `pyimagej-ai-guide.ipynb` - Interactive Colab notebook for learning

**Note**: These rulesets are kept in sync with the codebase via GitHub Actions automation.

## Key Files for Context

- `src/imagej/__init__.py` - Gateway initialization and `ij.py.*` API
- `src/imagej/convert.py` - All conversion functions
- `doc/Initialization.md` - Complete initialization guide
- `doc/Headless.md` - Headless mode and Xvfb usage
- `conftest.py` - Test fixture configuration
- `pyproject.toml` - Dependencies and project metadata
