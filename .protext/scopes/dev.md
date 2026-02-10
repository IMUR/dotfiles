# Scope: Development

## Focus
Template authoring, Go template syntax, chezmoi conventions, testing.

## Key Resources
- Templates: `dot_*.tmpl` files in project root
- Config templates: `dot_config/` subdirectory
- SSH config: `dot_ssh/`
- Run scripts: `run_onchange_*.sh.tmpl`

## Current Priorities
1. Template correctness across architectures (ARM64/x86_64)
2. Clean conditional logic using `.is_arm64` / `.is_x86_64`
3. Consistent naming: `dot_` prefix, `.tmpl` suffix, `executable_` prefix

## Patterns
- File naming: `dot_` → `.`, `executable_` → +x, `run_onchange_` → runs on change
- Template variables from `.chezmoi.toml.tmpl`
- Runtime detection: `_has_cmd` helper in `.profile`
- Shell layers: profile → shell RC → local overrides

## Cautions
- Go template whitespace control: use `{{-` and `-}}` carefully
- Test on single node before cluster-wide apply
- Don't delete templates without backup
