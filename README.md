# llm-instructions
Collections of instruction files built by and for LLMs

⚠️  **This is all untested and cannot be endorsed as fully functional** ⚠️

These instructions are intended as starting points for LLM assistance when working with ImageJ, SciJava, and related projects. Each file contains domain-specific knowledge to help LLMs better understand project architecture, conventions, and common patterns.

## Organization

Files are organized by who generated them:
- `copilot/` - Instructions generated with GitHub Copilot

## Usage

1. Clone this repository to a central location on your system
2. When working on a project, reference the relevant instruction file(s) in your LLM context
3. For downstream projects that use these dependencies, include the instruction files for the libraries you're working with

### Example
If you're working on ImageJ2 code, you might reference:
- `copilot/imagej2.md`
- `copilot/scijava-common.md`
- `copilot/imglib2.md`

## Contributing

These instructions evolve over time. Contributions and improvements are welcome, especially as the projects themselves change or as we discover better ways to convey information to LLMs.


