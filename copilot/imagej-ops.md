# ImageJ Ops Development Guide

## Architecture Overview

ImageJ Ops is a **plugin-based framework** for image processing algorithms using the **SciJava plugin system**. The key architectural pattern is that operations ("ops") are discovered at runtime and matched by name + parameter types (similar to Java method overloading).

### Core Concepts

- **Op**: Deterministic, type-safe operations implementing the `Op` interface (extends `Command`)
  - Must be annotated with `@Plugin(type = Ops.NamespaceName.OpName.class)`
  - Example: `@Plugin(type = Ops.Math.Add.class)` for a math addition operation
  
- **Namespaces**: Organize ops into functional groups (e.g., `math`, `filter`, `convert`)
  - Declared in `src/main/templates/net/imagej/ops/Ops.list`
  - Example: `math.add`, `filter.gauss`, `convert.uint8`
  
- **Op Execution**: Ops are invoked via `OpService` (accessed as `ops` in tests/code)
  - `ops.run("math.add", a, b)` - executes op and returns result
  - `ops.op("math.add", 5)` - returns an op instance for reuse

### Op Implementation Patterns

**Extend the appropriate abstract base class:**

- `AbstractUnaryFunctionOp<I, O>` - pure function: takes input I, returns new output O
- `AbstractUnaryComputerOp<I, O>` - mutates pre-allocated output O from input I
- `AbstractBinaryFunctionOp<I1, I2, O>` - two inputs, returns new output
- `AbstractBinaryComputerOp<I1, I2, O>` - two inputs, mutates output
- Inplace variants: `AbstractUnaryInplaceOp`, `AbstractBinaryInplaceOp`

**Example structure:**
```java
@Plugin(type = Ops.Math.Add.class)
public class Add<T extends NumericType<T>>
    extends AbstractBinaryComputerOp<T, T, T> 
    implements Ops.Math.Add {
    
    @Override
    public void compute(T in1, T in2, T out) {
        out.set(in1);
        out.add(in2);
    }
}
```

### Contingent Ops

Ops implementing `Contingent` run only when `conforms()` returns true. Used for ops with specific preconditions (e.g., dimension constraints, type requirements).

```java
@Override
public boolean conforms() {
    return input.numDimensions() == 2; // Only works on 2D images
}
```

## Code Generation System

**CRITICAL**: Do NOT edit generated files in `target/classes/`. Edit templates and regenerate.

- **Templates**: `src/main/templates/net/imagej/ops/`
  - `Ops.list` - defines all op namespaces and names
  - `Ops.vm` - Velocity template generating `Ops.java` interface hierarchy
  - **Build command**: `mvn clean compile` (runs Groovy script `generate.groovy`)

- **Generated outputs**: Marker interfaces like `Ops.Math.Add`, `Ops.Filter.Gauss`
  - Located in build output (not source controlled)
  - Used as plugin types in `@Plugin(type = ...)` annotations

## Testing Conventions

Extend `AbstractOpTest` which provides:
- `ops` field - OpService instance for running ops
- Helper methods: `assertIterationsEqual()`, `asArray()`, etc.

**Typical test structure:**
```java
public class MyOpTest extends AbstractOpTest {
    @Test
    public void testOperation() {
        Object result = ops.run("namespace.opname", input1, input2);
        assertEquals(expected, result);
    }
}
```

## Build & Development Workflow

```bash
# Full build with tests
mvn clean install

# Quick compile (regenerates templates)
mvn clean compile

# Run specific test
mvn test -Dtest=ClassName#methodName
```

**CI/CD**: Uses `.github/build.sh` which downloads standard SciJava build scripts

## Project Structure

```
src/main/java/net/imagej/ops/
├── Op.java, OpService.java       # Core interfaces
├── AbstractOp.java                # Base class for all ops
├── Namespace.java                 # Namespace marker interface
├── [namespace]/                   # Op implementations by namespace
│   ├── NamespaceNamespace.java   # Namespace implementation with @OpMethod methods
│   └── [ops].java                # Individual op implementations
└── special/                       # Special op types (computer, function, inplace)
    ├── computer/
    ├── function/
    └── inplace/

src/main/templates/                # Code generation templates
src/test/java/                     # Unit tests (extend AbstractOpTest)
```

## Adding a New Op

1. **Define in template** (if new namespace): Edit `src/main/templates/net/imagej/ops/Ops.list`
2. **Regenerate interfaces**: `mvn clean compile`
3. **Implement op**: Create class extending appropriate `Abstract*Op`, add `@Plugin` annotation
4. **Add to namespace** (if applicable): Add `@OpMethod` in `[Namespace]Namespace.java`
5. **Write test**: Extend `AbstractOpTest`, test via `ops.run()`

## Common Patterns

**Parameter injection** (via SciJava):
```java
@Parameter
private double sigma;  // Required parameter

@Parameter(required = false)
private int radius = 5;  // Optional with default
```

**Op chaining** - Ops can take other ops as parameters:
```java
@Parameter
private UnaryComputerOp<T, T> elementOp;  // Operation to apply per element
```

**Environment access** - All ops have `ops()` method returning their `OpEnvironment`:
```java
UnaryFunctionOp<T, R> myOp = ops().op("namespace.name", input);
```

## Key Dependencies

- **ImgLib2**: Core image data structures (`Img`, `RandomAccessibleInterval`, `Type`)
- **SciJava Common**: Plugin framework, contexts, parameters
- **ImageJ Common**: ImageJ-specific data structures
- **Apache Commons Math3**: Mathematical algorithms

## Style Guidelines

- Follow [ImageJ code style](http://imagej.net/Coding_style)
- Op names: lowerCamelCase (e.g., `addPoissonNoise`)
- Use small, focused commits with descriptive messages
- One op per file (except related inner classes)
