# Gemini Code Assistant Context

## Directory Overview

This repository, `crtr-config`, is a **Configuration Management** project for a single Raspberry Pi 5 node named "cooperator". It follows an **Infrastructure-as-Code (IaC)** methodology, acting as the **Single Source of Truth (SSoT)** for the node's entire configuration.

The core philosophy is to define the system's desired state declaratively in YAML files and use a set of tools to validate and apply that state.

### Key Directories:

*   `ssot/state/`: **This is the most important directory.** It contains the declarative YAML files that define the system state (network, services, domains, etc.). **Most edits will happen here.**
*   `tools/`: Contains the shell scripts used to manage and operate on the `ssot/state/` files. The main entry point is the `tools/ssot` script.
*   `.stems/`: Contains the documentation for the project's methodology, principles, and patterns. It's a good place to understand the "why" behind the structure.
*   `backups/`: Contains historical snapshots of configurations.
*   `dotfiles/`: A git submodule for managing user-level dotfiles via `chezmoi`.

## Key Files & Concepts

*   **`ssot/state/*.yml`**: These are the core state files.
    *   `network.yml`: Manages network interfaces, DNS (Pi-hole), DDNS, and NFS exports.
    *   `services.yml`: Defines `systemd` and `docker` services to be run.
    *   `domains.yml`: Configures the Caddy reverse proxy.
    *   `node.yml`: Defines the node's identity and hardware.
*   **`tools/ssot`**: The main CLI tool for interacting with the repository. It dispatches to other scripts in the `tools/` directory.
*   **Methodology (`.stems/METHODOLOGY.md`)**: The project follows a "Validation-First Deployment" lifecycle:
    1.  **Declaration**: Define state in `ssot/state/`.
    2.  **Validation**: Run `./tools/ssot validate` to check for errors.
    3.  **Deployment**: Run `sudo ./tools/ssot deploy` to apply the changes.
    4.  **Verification**: Run `./tools/ssot diff` to compare the live state against the desired state.

## Building and Running (Usage)

This is not a typical software project that you "build". Instead, you use the provided tools to manage the node's configuration.

### Primary Workflow

1.  **Edit State:** Modify one of the YAML files in `ssot/state/`.
    ```bash
    # Example: Edit network configuration
    vim ssot/state/network.yml
    ```

2.  **Validate Changes:** Before deploying, always run the validation script. It checks for syntax, security, and consistency errors.
    ```bash
    ./tools/ssot validate
    ```

3.  **See Potential Changes:** To see what changes will be made to the live system, use the `diff` command.
    ```bash
    ./tools/ssot diff
    ```

4.  **Deploy Changes:** Apply the configuration to the live system. This usually requires `sudo`.
    ```bash
    # Deploy all changes
    sudo ./tools/ssot deploy --all

    # Deploy changes for a specific service
    sudo ./tools/ssot deploy --service=caddy
    ```

### Other Useful Commands

*   **Discover Live State:** Capture the current running configuration and compare it to the SSoT.
    ```bash
    ./tools/ssot discover
    git diff ssot/state/
    ```
*   **Get Help:** The main `ssot` tool has built-in help.
    ```bash
    ./tools/ssot --help
    ```

## Development Conventions

*   **Declarative First:** Always define *what* you want in the `ssot/state/` YAML files, not *how* to achieve it. The tools handle the "how".
*   **Validation is Mandatory:** Never deploy without running `./tools/ssot validate` first.
*   **Idempotent Scripts:** The deployment scripts are designed to be idempotent, meaning they can be run multiple times without causing issues.
*   **Separation of Concerns:**
    *   System-level configuration is in this repository.
    *   User-level configuration (dotfiles) is managed by `chezmoi` in the `dotfiles/` submodule.
