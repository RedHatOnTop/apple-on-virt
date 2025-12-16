# Contributing to Apple-on-Virt

Thank you for your interest in contributing to this project!

## Development Workflow

This project uses LLM-assisted development with structured prompts and quality gates. Please refer to the following documentation:

- [Technical Specification](docs/spec/macOS_Monterey_ARM64_Execution_Environment_Specification.md)
- [LLM Development Prompts](docs/spec/LLM_Prompts_for_macOS_Emulator_Development.md)

## Code Style

- Use clear, descriptive variable and function names
- Comment complex logic only when necessary
- Follow existing code patterns in the repository

## Commit Messages

Use conventional commit format:
- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `refactor:` Code refactoring
- `test:` Test additions or modifications

## Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on ARM64 hardware
5. Submit a pull request with clear description

## Testing

All changes should be tested on:
- Apple Silicon Mac (M1/M2/M3) with HVF
- Linux ARM64 with KVM (if available)

## Questions?

Open an issue for discussion before making major changes.
