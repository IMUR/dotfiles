# Scope: Security

## Focus
Secrets handling, SSH configuration, credential management across cluster.

## Key Resources
- Infisical config: `.infisical.json`
- SSH managed files: `dot_ssh/`
- Git config: `dot_gitconfig.tmpl`
- Gitignore: `.gitignore`

## Current Priorities
1. Never commit secrets to templates
2. Keep .gitignore covering sensitive patterns
3. SSH key management across nodes

## Patterns
- Secrets via Infisical — never hardcoded in templates
- `.gitignore` excludes `.env*`, `.infisical.json`
- Template variables for cluster domain/paths — no hardcoded IPs

## Cautions
- `.infisical.json` is in repo but should not contain secrets
- Review `dot_ssh/` changes carefully — affects cluster access
- Never expose credentials in template conditionals
