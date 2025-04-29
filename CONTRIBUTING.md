# Contributing to OscarAICoder.jl

We welcome contributions to OscarAICoder.jl! Here's how you can help:

## Getting Started

1. Fork the repository
2. Clone your fork locally:
   ```bash
   git clone https://github.com/your-username/OscarAICoder.jl.git
   ```
3. Install the dependencies:
   ```bash
   julia --project -e 'using Pkg; Pkg.instantiate()'
   ```

## Development Guidelines

### Code Style
- Follow Julia's style guidelines
- Use descriptive variable names
- Add docstrings to all public functions
- Keep lines under 100 characters

### Testing
- Add tests for new features
- Ensure existing tests pass
- Run tests locally before submitting:
  ```julia
  julia --project -e 'using Pkg; Pkg.test("OscarAICoder")'
  ```

### Documentation
- Update relevant documentation
- Add examples for new features
- Keep README.md up to date

## Making Changes

1. Create a new branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. Make your changes
3. Add tests
4. Commit your changes:
   ```bash
   git add .
   git commit -m "feat: describe your changes"
   ```
5. Push to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```
6. Create a Pull Request

## Pull Request Guidelines

- Reference any related issues
- Include a clear description of changes
- Add relevant tests
- Update documentation
- Ensure CI passes

## Code Review Process

1. A maintainer will review your PR
2. You may be asked to make changes
3. Once approved, your changes will be merged

## Issue Reporting

1. Search existing issues first
2. Include:
   - Clear description
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details
   - Error messages (if any)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
