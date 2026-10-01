# Roadmap

This is a document that changes a lot.

## Status Legend

🟢 Done
🟡 In Progress
🔵 Planned
⚪ Idea / Untimed

## v0.0.1.x 🟡

-   [x] Set up Nix Flake
-   [x] Set up dev environment (including VSCode)
-   [ ] Basic directory structure
-   [ ] Write first human axioms (Modus Ponens, Set Theory, ...)
-   [ ] Implement a basic validation shell script in `nushell`
-   [ ] Test Kernel check pipeline end-to-end

## v0.0.2.x 🔵

-   [ ] **Storage Backend** (`src/store/`)
    -   [ ] Needs SHA-256 content hashing for theorem entries
    -   [ ] Needs Merkle Tree-like structures for theorem dependencies
    -   [ ] Query interface by hash or dependency
    -   [ ] In `gleam`
-   [ ] **Orchestration Layer** (`src/orch/`)
    -   [ ] Cluster manager
    -   [ ] Needs agent lifecycle management (`spawn`/`kill`/`timeout`)
    -   [ ] In `gleam`
-   [ ] **Validation Pipeline** (`src/validation/`)
    -   [ ] Analysis of proofs

## Parking Lot ⚪

-   [ ] Find a way to sandbox AI agents
-   [ ] Need a clean and easy way to store packages in the backend (could just use the `nix` language and derive statically)
-   [ ] Need to find the right AI agent for this
-   [ ] Need proper prompting strategies to force the model to generate the right output
-   [ ] How to deal with different axiomatic frameworks and possible conflicts between them? Maybe some weird universe splitting?
