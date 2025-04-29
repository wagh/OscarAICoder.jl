# OscarAICoder.jl Documentation

This directory contains the documentation for OscarAICoder.jl.

## Structure

- `manual/` - Main LaTeX documentation
- `examples/` - Example code demonstrating package usage
  - `algebra/` - Algebra examples
  - `calculus/` - Calculus examples
  - `linear_algebra/` - Linear algebra examples
- `figures/` - Figures and diagrams

## Building the Documentation

To build the documentation, run:

```bash
make
```

This will generate `manual.pdf` in the `manual/` directory.

## Adding Examples

1. Create a new directory in `examples/` for your topic
2. Add example `.jl` files demonstrating package usage
3. Update the manual to reference your examples

## Contributing

1. Add new examples in appropriate directories
2. Update the manual with new features
3. Add figures as needed
4. Run `make` to verify changes
