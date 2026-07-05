# greenTest

Clone this repo first on a new machine. It's the on-ramp for everything else Ecology Computing publishes.

GreenTests are extended READMEs: instead of just describing how to verify a language/toolchain is bootstrapped correctly, each one is a notebook (or equivalent) that actually does it - generates a small static site, serves it locally, and verifies the served output matches what was generated. If it goes green, that language is ready to use on this machine, not just assumed to be.

## Quickstart

1. Make sure you have `git` (usually already there, or one command/prompt away on any OS).
2. Clone whichever other Ecology Computing repos you're about to work on as siblings of this one (`vanilla-compost`, `ecology-computing.com`, `chriscorriere.com`, `maps`, ...).
3. Pick the language you need below, `cd` into it, and run its bootstrap script.
4. Read [`ECOLOGY.md`](./ECOLOGY.md) for the methodology this all sits inside - the guiding principles, the mapping approach, and the convention for working with this repo whether you're a person, an AI agent, or both.

## Starting a session

Opening prompt for a fresh CLI LLM session (Claude Code or otherwise), once you've cloned this repo:

> Let's chat about what we're working on. See greenTest. Update CLAUDE.md as needed. What do we need to pair on, what can we hand to a ralph loop?

This works whether or not the tool auto-discovers `AGENTS.md`/`CLAUDE.md` on its own - it explicitly points the session at this repo, asks it to keep the project's own `CLAUDE.md` current as you go, and forces the pair-vs-loop triage up front instead of letting that decision happen by default.

## Languages

| Language | Status | Verifies |
|---|---|---|
| Python | done | [vanilla-compost](https://github.com/EcologyComputing/vanilla-compost) |
| Node | done | [vanilla-compost](https://github.com/EcologyComputing/vanilla-compost) |
| Java | planned | TBD |
| C# | planned | TBD |
| Rust | planned | TBD |
| Go | planned | TBD |

Each one follows the same shape: `bootstrap.sh` gets the language's toolchain ready, then a notebook (or that language's closest equivalent) generates a tiny static site, serves it locally, and verifies the served output matches what was generated.

## Also here

- `ECOLOGY.md` - the methodology: guiding principles, mapping approach, how to work with this repo as a human, an agent, or both. `AGENTS.md` is a one-line pointer to it, kept only so tools that auto-discover that filename by convention still find their way here.
- `ralph-loop-template/` - a ready-to-copy scaffold for running an unattended agentic loop against a well-scoped batch of tasks, pre-filled with Ecology Computing's conventions.
