# Project Acrithis

**Acrithis** (named after <a href="https://wiki.warframe.com/w/Acrithis">Acrithis herself</a>) is a formally verified theorem database for eliminating AI hallucinations in mathematical proofs.
It achieves this by grounding every theorem in a trusted content-addressed store inspired by the <a href="https://nix.dev/manual/nix/2.24/store/">nix store</a>.

### Technologies:

<a href="https://gleam.run/"><img src="https://storage.ghost.io/c/dc/01/dc0121d6-1790-49f9-97f9-83c5d9d1790a/content/images/size/w960/2025/01/lucy.svg" alt="Gleam" width="30" height="30" /></a>
<a href="https://rust-lang.org/"><img src="https://raw.githubusercontent.com/graydon/rust-www/gh-pages/logos/rust-logo-256x256.png" alt="Rust" width="30" height="30" /></a>
<a href="https://lean-lang.org/"><img src="https://leodemoura.github.io/static/etaps2026/lean-logo.png" alt="Lean4" width="30" height="30" /></a>
<a href="https://nixos.org/"><img src="https://upload.wikimedia.org/wikipedia/commons/2/28/Nix_snowflake.svg?utm_source=en.wikipedia.org&utm_campaign=index&utm_content=original" alt="Nix" width="30" height="30" /></a>

<!--
<a href=""><img src="" alt="" width="30" height="30" /></a>
-->

## Methodologies

This section explains how Acrithis will work.
In the case of confusion with wording, please check `Glossary.md`

### LLM Agents:

Acrithis invokes multiple independent AI agents for writing `Lean4` proof scripts and reviewing them.

Acrithis first invokes AI agents for planning how to prove a theorem in a _graph-of-thought_ like structure, this is done with the goal of going to the lowest possible layer of proofs (axioms).
The results from these AI agents are to be checked by independent AI agents and validated.

Once the graph-of-thought has been determined, Acrithis will invoke another layer of AI agents for translating the graph-of-thought into an indexed linear set of axioms/postulates, definitions (axiomatic), conjectures, lemmas, propositions, theorems, and corollaries.

The modes'll define these in LaTeX and write their dependencies underneath.

Then Acrithis will invoke another layer of agents for placing these LaTeX axioms and theorems in an intermediate representation JSON IR of the following schema:

```TypeScript
type AcrithisIRNode =
    | {
        existing: string; // hash for axioms and theorems already in the store
    }
    | {
        id: string; // hash
        name: string; // theorem name
        ... // TBA
    }

type AcrithisIR = ReadonlyArray<AcrithisIRNode>
```

Acrithis'll then translate this IR into <a href="https://wiki.nixos.org/wiki/Derivations">nix derivations</a>.

### Validation:

Then, the `validation` program will go through the list of derivations, and determine if the derivation results in a correct `Lean4` proof.

If anything fails here, it'll be logged, and the process will be repeated in a manner that lets the agents re-use many of the previously correct proofs. Thus saving on token usage.

The `validation` will likely be done largely by a <a href="https://www.nushell.sh/">nushell</a> script.

### Store

The proofs themselves will be stored in an immutable, content-addressed format where:

- Content determines address (hash)
- Existing copies cannot be modified by LLMs
- Dependencies form a direct acyclic Merkle graph

#### Hashing

Hashing input:

```BASH
hash_input = theorem_name || statement_text || axiom_dependencies[] || proof_bytes
```

These'll be hashed in SHA-256.

This database will constitute different privileges for different users.
Any MCP based communication, for AI models, will be strictly limited to Append-Only and Read-Only permissions.
