# ImgLib2 AI Coding Agent Instructions

## Project Overview

ImgLib2 is a general-purpose, **multidimensional** image processing library for Java. The core design principle: write dimension-independent algorithms that work equally well for 2D, 3D, or n-dimensional data without changing code.

**Key Philosophy**: Interface-driven design with type-agnostic data access patterns. Algorithms operate on abstract interfaces (`RandomAccessible`, `Cursor`, `Type`) rather than concrete implementations.

## Core Architecture Patterns

### 1. Data Access Hierarchy

ImgLib2 uses a layered access model:

- **`RandomAccessible<T>`**: Infinite domain function over integer space (Z^n → T)
- **`RandomAccessibleInterval<T>`**: Bounded version with defined `Interval`
- **`Img<T>`**: Concrete pixel storage with min at origin (0,0,...,0)
- **`Cursor<T>`**: Iterator for sequential access (more efficient than `RandomAccess`)
- **`RandomAccess<T>`**: Positionable accessor for arbitrary coordinate access

**Critical**: Never assume `RandomAccessible` is defined everywhere—only within specified intervals. Use `Views.interval()` carefully and document boundaries.

### 2. Views Framework - Zero-Copy Transformations

The `Views` class (`net.imglib2.view.Views`) provides **virtual transformations** without copying data:

```java
// All these operations are O(1) in memory:
Views.zeroMin(img)              // Translate min to origin
Views.permute(img, 0, 1)        // Swap axes (e.g., XY → YX)
Views.hyperSlice(img, 2, 5)     // Extract (n-1)D slice at z=5
Views.extendBorder(img)         // Infinite extension with border replication
Views.interval(extended, bounds) // Define finite interval on infinite source
```

**Important**: `Views` operations are lazy—they create efficient accessors via `TransformBuilder`. When chaining, consider using the fluent API: `img.view().permute(0,1).zeroMin()`.

### 3. Type System

`Type<T>` represents pixel values. Types can be:
- **Value holders**: Store a single value (`createVariable()`)
- **Proxy types** (`NativeType`): Map to primitive arrays for efficiency

Common types in `net.imglib2.type.*`:
- Numeric: `FloatType`, `DoubleType`, `IntType`, `UnsignedByteType`
- Complex: `ComplexFloatType`
- Non-numeric: `ARGBType`, `BitType`

Types support arithmetic: `pixelA.add(pixelB)`, `pixelA.mul(2.0)`

### 4. Image Factories

Create images via `ImgFactory<T>`:
- `ArrayImgFactory`: Single contiguous array (fast, memory-limited to ~2GB)
- `CellImgFactory`: Chunked storage (for large images)
- `PlanarImgFactory`: One array per plane (2D-optimized)

```java
Img<FloatType> img = new ArrayImgFactory<>(new FloatType()).create(512, 512, 100);
```

## Essential Patterns

### Writing Dimension-Independent Algorithms

**DO**: Use interface types and iterate without hardcoded dimensions
```java
public static <T extends NumericType<T>> void process(RandomAccessibleInterval<T> img) {
    Cursor<T> cursor = Views.flatIterable(img).cursor();
    while (cursor.hasNext()) {
        cursor.next().mul(2.0);  // Works for 2D, 3D, nD
    }
}
```

**DON'T**: Assume specific dimensionality
```java
// ❌ BAD - assumes 2D
for (int y = 0; y < height; y++)
    for (int x = 0; x < width; x++)
```

### Efficient Iteration

**Prefer `Cursor` over `RandomAccess` for sequential access**:
```java
// Fast - optimal memory access
Cursor<T> cursor = img.cursor();
while (cursor.hasNext()) {
    T pixel = cursor.next();
    // process pixel
}

// Slow - use only when random access needed
RandomAccess<T> ra = img.randomAccess();
ra.setPosition(new long[]{x, y, z});
```

### Modern Loop Patterns with LoopBuilder

**Recommended** for multi-image operations (handles optimization automatically):
```java
LoopBuilder.setImages(input, output).forEachPixel((in, out) -> {
    out.set(in);
    out.mul(2.0);
});

// Multi-threading:
LoopBuilder.setImages(a, b, result)
    .multiThreaded()
    .forEachPixel((a, b, r) -> r.setReal(a.getRealDouble() + b.getRealDouble()));
```

See `net.imglib2.loops.LoopBuilder` for the most efficient pixel-wise operations.

## Development Workflows

### Building
```bash
mvn clean install          # Standard Maven build
mvn test                   # Run tests
```

### Code Generation
Some classes are generated from templates in `templates/` using `bin/generate.groovy`. If modifying templates, regenerate before committing.

### Testing Patterns
Tests use JUnit. Example pattern in `src/test/java/`:
```java
@Test
public void testSomething() {
    Img<FloatType> img = ArrayImgs.floats(10, 10);
    // Test dimension-independent code
}
```

## Key Packages

- `net.imglib2.*` - Core interfaces (Cursor, RandomAccess, Interval, etc.)
- `net.imglib2.img.*` - Concrete image implementations (ArrayImg, CellImg, etc.)
- `net.imglib2.type.*` - Pixel type hierarchy
- `net.imglib2.view.*` - Virtual transformation framework
- `net.imglib2.loops.*` - Modern iteration utilities (LoopBuilder)
- `net.imglib2.algorithm.*` - (Note: Many algorithms now in separate repositories)
- `net.imglib2.util.*` - Helper utilities (Intervals, Util)

## Common Pitfalls

1. **Don't call `getAt(position)` in loops** - Creates new `RandomAccess` each time. Use `randomAccess()` once, then reposition.

2. **Check iteration order**: `Views.flatIterable()` optimizes based on image storage. For guaranteed order, use specific iterator types.

3. **`Views.interval()` doesn't validate bounds** - Caller must ensure source is defined in the interval.

4. **Avoid mixing `int` and `long` coordinates** - Dimensions use `long[]`, not `int[]`, to support large images.

5. **Type parameters are critical** - `Type<T>` requires `T extends Type<T>` for recursive bounds.

## Project Conventions

- **License**: Simplified BSD (2-clause) - see license headers in all files
- **Code style**: Eclipse formatter configs in `doc/` directory
- **Package structure**: Follows interface-driven design - implementations in subpackages
- **Minimal dependencies**: Core library has very few dependencies (see `pom.xml`)
- **Part of SciJava**: Integrates with ImageJ2, Fiji, SCIFIO ecosystem

## References

- [ImgLib2 Blog](https://imglib.github.io/imglib2-blog) - Tutorials and examples
- [Online Javadoc](http://javadoc.imagej.net/ImgLib2/)
- [ImgLib2 Examples](http://imagej.net/ImgLib2_Examples)
- Parent POM: `pom-scijava` version 41.0.0
