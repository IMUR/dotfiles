# Configuration Validation System

**Multi-stage validation following the Validation-First Deployment methodology**

## Overview

This validation system implements the principles from `.stems/METHODOLOGY.md`:

> **Validation-First Deployment**: Nothing touches production without validation.
> Multiple validation gates: syntax → simulation → approval → apply.
> Fail fast, fail safe, fail informatively.

## Validation Stages

### Stage 1: Syntax Validation ✅
**Purpose**: Ensure YAML files are parseable

```bash
./tools/ssot validate --stage 1
```

**Checks**:
- Valid YAML syntax
- No parsing errors
- Files can be loaded

**Severity**: Critical - deployment will fail

### Stage 2: Security Validation ✅
**Purpose**: Detect exposed secrets and insecure configurations

```bash
./tools/ssot validate --stage 2
```

**Checks**:
- No plaintext secrets (tokens, passwords, API keys)
- No UUID-format tokens in config files
- TLS verification warnings
- Open bind warnings (0.0.0.0)

**Severity**: Warning by default, critical with `--strict`

**Implementation**: `tools/lib/validate-security.sh`

### Stage 3: Consistency Validation ✅
**Purpose**: Validate cross-file references

```bash
./tools/ssot validate --stage 3
```

**Checks**:
- Domain services reference existing services
- IP addresses consistent across files
- Cluster node references valid

**Severity**: Warning by default, critical with `--strict`

**Implementation**: `tools/lib/validate-consistency.sh`

### Stage 2.5: Schema Validation (Optional) 🚧
**Purpose**: Validate against JSON schemas

**Status**: Schemas defined in `ssot/schemas/`, validator optional

This can be added later if needed. Following **Progressive Disclosure**: simple tasks remain simple.

## Usage

### Basic Validation
```bash
# Run all validation stages
./tools/ssot validate

# Expected output:
# Stage 1: Syntax Validation    ✓
# Stage 2: Security Validation  ✓ (or warnings)
# Stage 3: Consistency Validation ✓ (or warnings)
# ✅ All validations passed!
```

### Strict Mode
```bash
# Treat warnings as errors
./tools/ssot validate --strict

# Use before critical deployments
```

### Individual Stages
```bash
# Run only syntax check (fast)
./tools/ssot validate --stage 1

# Run only security check
./tools/ssot validate --stage 2

# Run only consistency check
./tools/ssot validate --stage 3
```

### Help
```bash
./tools/ssot validate --help
```

## Exit Codes

Following the **Fail Fast** principle:

- **0** - All validations passed
- **1** - Critical errors found (must fix before deploy)
- **2** - Warnings found (--strict mode only)

## Integration with Workflow

### Before Editing
```bash
# Verify current state is valid
./tools/ssot validate
```

### After Editing
```bash
# 1. Validate your changes
./tools/ssot validate

# 2. See what will change
./tools/ssot diff

# 3. Deploy if validated
sudo ./tools/ssot deploy --all
```

### In Git Hooks
```bash
# .git/hooks/pre-commit
#!/bin/bash
./tools/ssot validate --strict
if [ $? -ne 0 ]; then
    echo "Validation failed - fix errors before committing"
    exit 1
fi
```

## Philosophy Alignment

### From `.stems/PRINCIPLES.md`

#### P4: Safety Through Validation
✓ Changes are validated before application, always
✓ Validation is not optional
✓ Multiple validation stages catch different error classes

#### O1: Fail Fast, Fail Safe
✓ Errors detected early (syntax first)
✓ Handled gracefully (clear messages)
✓ Stops at first critical error

#### O4: Observability Over Debugging
✓ Validation output is comprehensive
✓ Changes shown before application
✓ State is always discoverable

#### Choose Boring Technology
✓ Bash scripts (proven, stable)
✓ Python YAML parser (standard library)
✓ Simple grep/sed for pattern matching
✓ Text-based output

## Validation Architecture

```
validate.sh (orchestrator)
├── Stage 1: Syntax
│   └── Python yaml.safe_load()
├── Stage 2: Security
│   └── lib/validate-security.sh
│       ├── Pattern matching for secrets
│       ├── UUID detection
│       └── Config security checks
└── Stage 3: Consistency
    └── lib/validate-consistency.sh
        ├── Service references (yq)
        ├── IP consistency
        └── Cluster node validation
```

## Adding New Validations

### Adding a Security Check

Edit `tools/lib/validate-security.sh`:

```bash
# Add to SECRET_PATTERNS array
SECRET_PATTERNS=(
    'token:'
    'password:'
    'your_new_pattern:'  # Add here
)
```

### Adding a Consistency Check

Edit `tools/lib/validate-consistency.sh`:

```bash
check_your_validation() {
    local file1="$1"
    local file2="$2"
    local issues=0

    # Your validation logic here
    # Return number of issues found

    return $issues
}

# Call from main()
check_your_validation "$STATE_DIR/file1.yml" "$STATE_DIR/file2.yml"
```

### Adding a New Stage

1. Create `tools/lib/validate-yourstage.sh`
2. Follow the pattern of existing validators
3. Add to `tools/validate.sh`:

```bash
validate_yourstage() {
    if [[ -f "$LIB_DIR/validate-yourstage.sh" ]]; then
        source "$LIB_DIR/validate-yourstage.sh"
        main "$STATE_DIR"
        return $?
    else
        warning "Your stage validator not found, skipping"
        return 0
    fi
}

# Add to main() function
if [[ -z "$STAGE" ]] || [[ "$STAGE" == "4" ]]; then
    validate_yourstage
    ((stages_run++))
fi
```

## Troubleshooting

### "yq not installed" Warning
```bash
# Install yq for consistency validation
sudo apt install yq

# Or continue without consistency checks
# (validation will skip and warn)
```

### False Positive Security Warnings

Add to safe patterns in `validate-security.sh`:

```bash
SAFE_PATTERNS=(
    'CHANGEME'
    'your-token-here'
    'YOUR_PATTERN_HERE'  # Add your placeholder pattern
)
```

### Validation Too Strict

Use regular mode (not --strict) for development:

```bash
# Warnings allowed
./tools/ssot validate

# Strict for production
./tools/ssot validate --strict
```

## Future Enhancements

Following **Progressive Disclosure**, these are optional additions:

- [ ] JSON Schema validation (schemas exist in `ssot/schemas/`)
- [ ] Network connectivity validation
- [ ] Service health checks
- [ ] Backup verification
- [ ] Configuration diff preview

These can be added incrementally as needed.

## References

- Methodology: `.stems/METHODOLOGY.md`
- Principles: `.stems/PRINCIPLES.md`
- Schemas: `ssot/schemas/README.md`
- Lifecycle: `.stems/LIFECYCLE.md`

## Summary

This validation system provides:

✅ **Multi-stage validation** - Catch different error classes
✅ **Fail-fast behavior** - Stop at first critical error
✅ **Clear output** - Know exactly what's wrong
✅ **Simple tools** - Bash scripts, standard utilities
✅ **Progressive disclosure** - Simple by default, powerful when needed
✅ **Methodology-aligned** - Follows `.stems/` principles

**Remember**: "Simple systems, professional practices."

---

**Quick Reference**:

```bash
# Before deploy
./tools/ssot validate

# Strict mode
./tools/ssot validate --strict

# Single stage
./tools/ssot validate --stage 1

# Help
./tools/ssot validate --help
```
