# SSOT Configuration Schemas

This directory contains JSON Schema definitions for validating the YAML state files in `ssot/state/`.

## Purpose

Following the **Validation-First Deployment** methodology, these schemas provide:

1. **Structure Validation** - Ensure required fields are present
2. **Type Safety** - Verify data types match expectations
3. **Format Validation** - Check IPs, hostnames, ports, etc.
4. **Documentation** - Schemas serve as machine-readable specs

## Philosophy

From `.stems/METHODOLOGY.md`:

> **Validation-First Deployment**: Nothing touches production without validation.
> Multiple validation gates: syntax → simulation → approval → apply.

These schemas support the multi-stage validation pipeline:
- **Stage 1**: Syntax (YAML parseable)
- **Stage 2**: Structure (matches schema) ← These schemas
- **Stage 3**: Security (no secrets exposed)
- **Stage 4**: Consistency (cross-file references valid)

## Available Schemas

| Schema | State File | Purpose |
|--------|------------|---------|
| `node.schema.json` | `state/node.yml` | Node identity, hardware, OS |
| `services.schema.json` | `state/services.yml` | Service definitions |
| `domains.schema.json` | `state/domains.yml` | Domain routing, reverse proxy |
| `network.schema.json` | `state/network.yml` | Network config, DNS, DDNS, NFS |

## Usage

### Option 1: Manual Validation (Optional)

Install JSON Schema validator:
```bash
# Using Python
pip install pyyaml jsonschema

# Then validate
python3 -c "
import yaml, json, jsonschema
with open('ssot/state/node.yml') as f:
    config = yaml.safe_load(f)
with open('ssot/schemas/node.schema.json') as f:
    schema = json.load(f)
jsonschema.validate(config, schema)
print('✓ Valid')
"
```

### Option 2: Integrated Validation

The `ssot validate` command uses these schemas automatically:

```bash
# Run all validation stages
./tools/ssot validate

# Run only schema validation (when implemented)
./tools/ssot validate --stage 2
```

## Schema Design Principles

Following `.stems/PRINCIPLES.md`:

### P2: Configuration as Data
- Schemas define structure (not code)
- Validation tools handle execution
- Humans handle decisions

### P3: Explicit Over Implicit
- All required fields explicitly listed
- All formats explicitly validated
- All constraints explicitly specified

### D3: Idempotency Ensures Safety
- Schema validation is idempotent
- Running multiple times = same result
- No side effects

## Schema Examples

### Basic Field Validation
```json
{
  "hostname": {
    "type": "string",
    "pattern": "^[a-z][a-z0-9-]*$",
    "minLength": 1,
    "maxLength": 63
  }
}
```

### Format Validation
```json
{
  "internal_ip": {
    "type": "string",
    "format": "ipv4"
  },
  "port": {
    "type": "integer",
    "minimum": 1,
    "maximum": 65535
  }
}
```

### Enum Constraints
```json
{
  "role": {
    "type": "string",
    "enum": ["gateway", "compute", "storage", "worker", "control"]
  }
}
```

### Conditional Validation
```json
{
  "if": {
    "properties": { "type": { "const": "systemd" } }
  },
  "then": {
    "required": ["binary", "unit_file", "restart"]
  }
}
```

## Extending Schemas

When adding new configuration:

1. **Add to appropriate schema** - Follow existing patterns
2. **Test validation** - Ensure it catches errors
3. **Update this README** - Document new fields
4. **Commit to git** - Schemas are part of truth

### Example: Adding New Field

```json
{
  "properties": {
    "new_field": {
      "type": "string",
      "description": "What this field does",
      "pattern": "^[a-z]+$",
      "minLength": 1
    }
  },
  "required": ["new_field"]
}
```

## Schema Evolution

Schemas evolve with your configuration:

- **Backward compatible changes** - Add optional fields
- **Breaking changes** - Version the schema, document migration
- **Always test** - Validate against existing configs

## Relationship to Methodology

From `.stems/LIFECYCLE.md`:

```
Phase 2: Validation
Templates → Syntax Check → Schema Check → Diff
```

Schemas implement the "Schema Check" phase:
1. Syntax ✓ (YAML parseable)
2. Schema ✓ (matches expected structure) ← These schemas
3. Diff (show what will change)

## Current Status

**Note**: Schema validation is currently **optional**. The core `ssot validate` command runs:

✅ **Stage 1**: Syntax validation (YAML parseable)
✅ **Stage 2**: Security validation (no secrets)
✅ **Stage 3**: Consistency validation (cross-file refs)

🚧 **Schema validation**: Can be added as Stage 2.5 if needed

This follows the principle of **Progressive Disclosure**: Simple tasks remain simple. Schema validation is available but not required.

## References

- JSON Schema specification: https://json-schema.org/
- YAML + JSON Schema guide: https://json-schema.org/implementations.html
- Our methodology: `.stems/METHODOLOGY.md`
- Our principles: `.stems/PRINCIPLES.md`

---

**Remember**: "Simple systems, professional practices."

Schemas provide professional validation without adding complexity.
