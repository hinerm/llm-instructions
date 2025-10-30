# llm-instructions
Collections of instruction files built by and for LLMs

⚠️  **This is all untested and cannot be endorsed as fully functional** ⚠️

These instructions are intended as starting points for LLM assistance when working with ImageJ, SciJava, and related projects. Each file contains domain-specific knowledge to help LLMs better understand project architecture, conventions, and common patterns.

## Quick Start

**See [INDEX.md](INDEX.md)** for a comprehensive guide to which files to use for different tasks.

### Common Scenarios

**Working on SciJava projects?** Start with:
- `copilot/scijava-foundation.md` (shared concepts across all SciJava projects)
- Plus the specific project file(s) you're working on

**Developing ImageJ2 algorithms?**
- `copilot/scijava-foundation.md`
- `copilot/imglib2.md` (data structures)
- `copilot/imagej-common.md` (ImageJ data model)
- `copilot/imagej-ops.md` (if using the Ops framework)

**Building on the script editor?**
- `copilot/scijava-foundation.md`
- `copilot/scijava-script-editor.md`

## Organization

Files are organized by the dev environment they were generated in:
- `copilot/` - Instructions generated with GitHub Copilot in VS Code
  - `scijava-foundation.md` - **Start here** for shared SciJava concepts
  - Individual project files for specific components
  - `langchain4j-core-module.md` - Non-ImageJ project (LLM framework)

**See [INDEX.md](INDEX.md)** for:
- Task-based file selection guide
- Dependency relationships between files
- Recommended file combinations for common workflows

## Usage

### Automated Setup with init.sh

The easiest way to add LLM instructions to your project is using the `init.sh` script:

```bash
./scripts/init.sh <target_project_path> <environment> <file_lists...>
```

**Arguments:**
- `target_project_path`: Path to your project root where instructions will be created
- `environment`: Either `copilot` (creates `.github/copilot-instructions.md`) or `claude` (creates `.clauderc`)
- `file_lists`: One or more lists of markdown files to merge
  - Format: `[directory:]file1,file2,file3`
  - Directory defaults to `copilot` if not specified
  - `.md` extension is optional
  - Multiple lists can be space-separated

**Examples:**

```bash
# Basic SciJava project
./scripts/init.sh ~/my-scijava-project copilot scijava-foundation,scijava-common

# ImageJ2 algorithm development
./scripts/init.sh ~/my-imagej2-plugin copilot scijava-foundation,imglib2,imagej-common,imagej-ops

# Multiple file lists (same as above)
./scripts/init.sh ~/my-imagej2-plugin copilot copilot:scijava-foundation,imglib2 copilot:imagej-common,imagej-ops

# For Claude Code
./scripts/init.sh ~/my-project claude scijava-foundation,scijava-common
```

The script will merge all specified instruction files into the appropriate location for your chosen environment.

### Manual Usage

Alternatively, you can manually reference the instruction files:

1. Clone this repository to a central location on your system
2. When working on a project, reference the relevant instruction file(s) in your LLM context
3. **Start with `scijava-foundation.md`** if working on any SciJava-based project
4. Add specific project files as needed (see INDEX.md for guidance)

### Reducing Redundancy

Many projects share common patterns (plugin system, dependency injection, build workflows). To avoid repetition:
- Ask an LLM to clean up your merged instructions files
- Load `copilot/scijava-foundation.md` once for shared concepts
- Load only project-specific files for implementation details
- Refer to INDEX.md for optimal file combinations

**Furthermore**, as you likely will not need to these instrcuctions in EVERY instance, you can also rename the files and just include them in the conversations they are actually needed.

## Contributing

These instructions evolve over time. Contributions and improvements are welcome, especially as the projects themselves change or as we discover better ways to convey information to LLMs.

When adding new instruction files:
1. Place them in the appropriate directory (`copilot/`, etc.)
2. Update `INDEX.md` with the new file's relationships and use cases
3. Consider whether content should be in `scijava-foundation.md` (if shared across projects)


