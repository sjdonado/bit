# Contributing Guidelines

We welcome contributions from the community! Please follow these guidelines to help maintain consistency and quality in the project.

## Code of Conduct
This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold its terms.

### Requirements
- Crystal 1.0+
- Shards package manager
- SQLite3

## Local Development

- linux
```bash
sudo apt-get update && sudo apt-get install -y crystal libssl-dev libsqlite3-dev
```

- macos
```bash
brew tap amberframework/micrate
brew install micrate
```

## Run
```bash
shards run bit
```

- Generate the `X-Api-Key`

```bash
shards run cli -- --create-user=Admin
```

- Run tests

```bash
ENV=test crystal spec
```


## How to Contribute

### 1. Fork the Repository
Click the "Fork" button at the top-right of the [repository page](https://github.com/sjdonado/bit).

### 2. Clone Your Fork
```bash
git clone https://github.com/YOUR_USERNAME/bit.git
cd bit
```

### 3. Create a Feature Branch
```bash
git checkout -b feat/your-feature-name
```

### or for bug fixes:

```bash
git checkout -b fix/issue-description
```

### 4. Develop Your Changes
- Ensure changes match the project scope
- Write clear commit messages
- Include tests for new functionality
- Update documentation when applicable

### 5. Commit Changes
```bash
git commit -am 'Add descriptive commit message'
```

### 6. Push to GitHub
```bash
git push origin your-branch-name
```

### 7. Create a Pull Request
1. Go to the [original repository](https://github.com/sjdonado/bit)
2. Click "New Pull Request"
3. Select your fork and branch
4. Add a clear description including:
   - Purpose of changes
   - Related issues (if applicable)
   - Testing performed

## Pull Request Guidelines
- Keep PRs focused on a single feature/bugfix
- Ensure all tests pass
- Update documentation in the same PR
- Use descriptive titles (e.g., "Add URL validation" not "Update code")
- Reference related issues using #issue-number

## Reporting Issues
When opening an issue, please include:
1. Description of the problem
2. Steps to reproduce
3. Expected vs actual behavior
4. Environment details (OS, Crystal version, etc)

For feature requests:
- Explain the problem you're trying to solve
- Suggest potential implementations

## License
By contributing, you agree that your contributions will be licensed under the [license](LICENSE).
