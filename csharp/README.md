# GreenTest: C#

The C# GreenTest for Ecology Computing. Same purpose as python's and js's: bootstrap the
language, generate a small static site, serve it locally, and verify it's being served
correctly - proof C# is ready to use on this machine, not just assumed to be.

## Why this one looks different from the others

Python and JS ship `greentest.ipynb`, a Jupyter notebook. C# doesn't.
This is a deliberate choice, not an oversight. Here's the reasoning,
so nobody "fixes" it back into a notebook later.

Microsoft's own C#/F#/PowerShell Jupyter kernel, **.NET Interactive** (formerly
Polyglot Notebooks), was deprecated by Microsoft during 2026: the VS Code extension on
March 27, the kernel itself on April 24, and the `dotnet/interactive` GitHub repo was
archived shortly after. It still runs if you install it, but per Microsoft: no new
features, no bug fixes, and security issues reported after the deprecation date go
unaddressed. Building this repo's onboarding path for a new language on top of an
already-archived project didn't seem worth it.

Microsoft's own recommended replacement for C# specifically is **file-based apps**, a
.NET 10 feature: a single ordinary `.cs` file that runs directly with `dotnet run
file.cs` (or executes directly on Linux/macOS via a shebang line), no `.csproj`
required. So `greentest.cs` here plays the role python/js's `greentest.ipynb` plays -
it's the required first stop, walking through the same 7 steps top to bottom with the
same narration, just as a script instead of notebook cells. It also runs on the plain
CLI by design, since the C# GreenTest needed to be runnable that way regardless of
notebook tooling.

The deliverable list allowed for `greentest.ipynb` *or* a `.csx` script for exactly this
kind of situation. `greentest.cs` (a file-based app) is that fallback, using the format
Microsoft is actually investing in going forward rather than `.csx` scripting tools that
predate it.

One consequence: because file-based apps only support a single file on the current
stable SDK (multi-file support via `#:include` is a **.NET 11 preview** feature as of
this writing, not something to depend on for a script other people are meant to run),
`greentest.cs` also absorbs the role the optional standalone smoketest script would have
played. Run it with `--quick` for a fast, unnarrated pass instead of maintaining a
second near-duplicate file:

```bash
./greentest.cs             # narrated, full explanations - the "notebook" experience
./greentest.cs --quick     # same steps, minimal output - for repeat runs
```

## What it actually does

Same shape as python/js, verified against
[vanilla-compost](https://github.com/EcologyComputing/vanilla-compost):

0. Confirm the .NET SDK is new enough (10+) for file-based apps.
1. Point at your `vanilla-compost` clone (`../../vanilla-compost` by default, override
   with `VANILLA_COMPOST`).
2. Confirm it's a real git clone with the files this script needs - via an embedded bash
   block, the same way python's notebook uses a `%%bash` cell. That block can be
   copy-pasted into a terminal and run on its own.
3. Leave a timestamped note in `greenTest-Message.md`, copied into
   `vanilla-compost/src/posts/`.
4. Generate `posts.html`. `vanilla-compost` has `generate_posts.py` and
   `generate_posts.js` for python/js to call, but no C# equivalent - adding one there
   was out of scope for this PR, so this step is a direct C# port of that same title
   /date-extraction and template-insertion logic, living in `greentest.cs` itself.
5. Serve `vanilla-compost/src` locally on `http://localhost:8080/` using
   `System.Net.HttpListener` from the standard library - no external packages, same as
   python's `http.server` and js's `server.js`.
6. Fetch `posts.html` back and verify it matches what was generated, and that the sample
   post shows up.
7. Clean up.

If it goes green, C# is bootstrapped and working end to end on this machine.

## Setup

```bash
cd csharp
./bootstrap.sh
./greentest.cs
```

`bootstrap.sh` installs the .NET SDK (LTS channel) into `$HOME/.dotnet` using
Microsoft's official install script, no system package manager needed for the SDK
itself, so it works the same way across distros, including ones that don't package
.NET at all or only ship an outdated version. Unlike python/js, there's no
Jupyter/venv setup needed here - a file-based app has no notebook runtime dependency.

One real dependency it does reach for `apt-get` for, when needed: `libicu` (see
"What this surfaced" below) - that's a hard runtime requirement of .NET itself on
bare Debian-family systems, not something worth avoiding just for the sake of
avoiding a package manager call.

On Windows, use `dotnet run greentest.cs` instead of `./greentest.cs` - shebang-line
execution is a Linux/macOS thing. `bootstrap.sh` also handles Windows specially: Git
Bash/MSYS/Cygwin can't use the Linux/macOS install script, so it automates the
install via `dotnet-install.ps1` through `powershell.exe` instead, falling back to
manual `winget`/installer instructions if PowerShell isn't reachable.

## What this surfaced

Verified end-to-end, fresh install each time, on: Steam Deck (SteamOS), Windows 10
via Git Bash, Linux Mint, and a clean `debian:bookworm` container (Podman) - not just
repeated runs on an already-set-up machine.

Also validated against real external C# projects pulled from GitHub, not just our own
generator: `dotnet/samples`' Orleans `HelloWorld` (console app, live NuGet restore)
and `TicTacToe` (a full ASP.NET Core MVC + Orleans web app) both built and ran with
nothing but `bootstrap.sh` having been run first.

One real gap `bootstrap.sh` had to learn to handle: a bare/minimal Debian container is
missing `libicu`, a hard runtime dependency of .NET itself, not something specific to
this GreenTest - `dotnet` crashes outright without it, even `dotnet --version`. Never
showed up on a real desktop Linux install (Deck, Mint already have it via something
else), purely a minimal-container thing. `bootstrap.sh` now detects this specifically
and installs `libicu72` via `apt-get` when available, falling back to manual
instructions (including the documented `DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1`
escape hatch) when it isn't.

## Requirements

- .NET SDK 10 or newer (file-based apps require it; `bootstrap.sh` installs it if
  needed)
- `bash` and `git` (used by the Step 2 clone check)
- A `vanilla-compost` clone as a sibling of this repo