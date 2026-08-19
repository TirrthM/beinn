# Project Governance

This document outlines the governance model for the Beinn open-source project.

## Project Roles

### 1. Core Maintainers
Maintainers have push access to the repository and are responsible for reviewing PRs, managing releases, and guiding the overall architectural vision.
- Current Maintainers: @TirrthM

### 2. Contributors
Anyone who submits a pull request, opens an issue, or helps with documentation is considered a contributor. Contributors who demonstrate consistent, high-quality involvement may be nominated to become maintainers.

## Decision Making Process

- **Minor Changes:** Bug fixes and small UI tweaks can be merged by any single maintainer after a successful CI run.
- **Major Features:** New features, architectural changes, or significant dependency updates require a written proposal in the GitHub Discussions or a detailed Issue. It must be approved by at least two maintainers.
- **Consensus:** We aim for consensus. If consensus cannot be reached, the project lead/creator holds the final decision-making authority.

## Release Cadence
- **Patches:** Released as needed for critical bug fixes.
- **Minor Versions:** Released monthly, bundling non-breaking features.
- **Major Versions:** Released when significant architectural or breaking API changes are introduced.
