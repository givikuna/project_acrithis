# Project Acrithis

<!--
<a href=""><img src="" alt="" width="30" height="30" /></a>
-->

**Acrithis** (named after <a href="https://wiki.warframe.com/w/Acrithis">Acrithis herself</a>) is a formally verified theorem database for eliminating AI hallucinations in mathematical proofs.
It achieves this by grounding every theorem in a trusted content-addressed store inspired by the <a href="https://nix.dev/manual/nix/2.24/store/">nix store</a>.

### Technologies:

<a href="https://gleam.run/"><img src="https://storage.ghost.io/c/dc/01/dc0121d6-1790-49f9-97f9-83c5d9d1790a/content/images/size/w960/2025/01/lucy.svg" alt="Gleam" width="30" height="30" /></a>
<a href="https://rust-lang.org/"><img src="https://raw.githubusercontent.com/graydon/rust-www/gh-pages/logos/rust-logo-256x256.png" alt="Rust" width="30" height="30" /></a>
<a href="https://lean-lang.org/"><img src="https://leodemoura.github.io/static/etaps2026/lean-logo.png" alt="Lean4" width="30" height="30" /></a>
<a href="https://nixos.org/"><img src="https://upload.wikimedia.org/wikipedia/commons/2/28/Nix_snowflake.svg?utm_source=en.wikipedia.org&utm_campaign=index&utm_content=original" alt="Nix" width="30" height="30" /></a>
<a href="https://lustre.hexdocs.pm/"><img src="https://avatars.githubusercontent.com/u/145234907?s=200&v=4" alt="Lustre" width="30" height="30" /></a>

<!--
<a href=""><img src="" alt="" width="30" height="30" /></a>
-->

## Methodologies

This section explains how Acrithis will work.
In the case of confusion with wording, please check `Glossary.md`

Acrithis invokes multiple independent AI agents for writing `Lean4` proof scripts and reviewing them.
And then places these results in a database. Allowing models to pull from this database for any reason.

This creates a trustable (and human-reviewed) single-source-of-truth, lessening hallucinations.

### LLM Agents:

Acrithis first invokes AI agents for planning how to prove a theorem in a _graph-of-thought_ like structure, this is done with the goal of going to the lowest possible layer of proofs (axioms).
The results from these AI agents are to be checked by independent AI agents and validated.

Once the graph-of-thought has been determined, Acrithis will invoke another layer of AI agents for translating the graph-of-thought into an indexed linear set of axioms/postulates, definitions (axiomatic), conjectures, lemmas, propositions, theorems, and corollaries.

The modes'll define these in LaTeX and write their dependencies underneath.

Then, Acrithis will invoke another layer of agents for placing these LaTeX axioms and theorems into `Lean4` proofs. If the axiom or theorem already exists in the `store` (explained in the last section), it'll simply point to that address.

Then, the resulting outputs will be compiled into an intermediate representation (IR) JSON of the following schema:

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

#### Human-verified Chunks

The database itself will be shipped by default with many axioms in many areas of mathematics, various foundational theorems, lemmas, and proofs.
And common proof strategies such as the Pigeonhole Principle.

This ensures the models have a human-verified truth layer for many things that they'll need to be defining.
Humans can add more things by hand as well, ensuring that the model only has to prove things that haven't yet been proven.

#### Hashing

The hash will be generated using NAR-like serialization, likely relying on BLAKE3 and CID.
This is to have a self-describing but still unique hash per object.

As recall: AI Generated LaTeX Proof -> AI Generated Lean Proof -> JSON IR -> Nix IR -> Acrithis Store Object (ASO).

#### Nodes and Artifacts

Nodes'll contain multiple fields:

- id: the string hash
- name: string
- type: enum: axiom, definition, lemma, theorem, corollary, conjecture
- statement_text: string
- lean_source: string
- latex_statement: string
- json_ir: string
- dependencies: array\<\{hash and role (import, uses_axiom, uses_lemma, etc...)\}\>
- closure_depth: int distance to the deepest dependency
- options: lean options (like maxHeartbeats)
- trust_level: enum: axiom, human_verified, machine_verified, conjecture, unverified
- validation_status: enum: pending, passed, failed, skipped, errored
- validation_log: string (lean4checker, axiom checks, acrithis checking script output)
- has_sorry: bool
- created_at: timestamptz
- created_by: string
- agent_model: Maybe string
- prompt_hash: the prompt as a hash
- reviewer_signatures: signatures from humans that verified the proofs (the more signatures that one has, the higher its chance of being used in a proof) (this will not apply to axioms, as they are always seen as correct).
- nix_ir: string
- olean: path pointing to binary file for lean
- store_path: path to the object in the store
- size_bytes: bigint
- full_prompt_history: string, describes all prompts, all thought processes, and the multiple AI models (outputs from all of them) on the path to creating this node.
- tags: string (combinatorics, linear algebra, abstract algebra, category theory, etc...)
- search_vector: tsvector, full-text search index of the name and statement
- exrp: lean kernel-level expression

#### SQLite

The actual database behind the store will be SQLite.
The Merkle DAG will be mapped to this database.
Objects'll point to the store folder (say `./acrithis/store`) that contains the proofs in a nix package like format: `./acrithis/store/a1b2c3d3/something.lean`.

#### Acyclicity

SQLite itself does not guarantee acyclicity, but this is necessary for proofs to work, and for the hashing and IR system to not break.
As such, Acrithis'll use an algorithm for every object added to the store. If a cycle emerges, it will not be allowed and will be flagged as an error.

#### Nix Parser

Acrithis'll support a simplified subset of the Nix programming language.
It will parse the Nix code to understand how an object is to be structured in the Acrithis store. And then construct that object.
This subset of Nix will be referred to as ANix (Acrithis Nix).
ANix is human-writeable and readable, as it is a proper, nice-to-read IR.

#### Web UI

There will be a Web UI provided by Acrithis to allow for humans to add, remove, and otherwise manage the store.
This includes but is not limited to:

- Adding theorems
- Adding proofs
- Verifying proofs
- Managing AI Models
- Plugging in AI Models
- Checking logs
- Changing prompts
- etc...

The Web UI will be written in [lustre](https://lustre.hexdocs.pm/) to keep the code-base in majority gleam.

#### Concurrency

Due to the BEAM VM, gleam will use an actor model here to be able to take in input from so many models at once cleanly.

#### Access/Permission Control

Acrithis store will have different privileges for different users.
Any MCP based communication, for AI models, will be strictly limited to Append-Only and Read-Only permissions.

The strict privilege separation'll help avoid rogue AI agents damaging aspects of the database.

## COPYRIGHT NOTE:

The name of this project is `Project Acrithis`, in reference to Acrithis from the video game, Warframe by Digital Extremes.
The copyright to this name is not mine, and I am not affiliated with Digital Extremes in any form.
The name simply pays homage to their work and does not attempt, or want to, pertain to Digital Extremes in any form besides paying homage to the character.
