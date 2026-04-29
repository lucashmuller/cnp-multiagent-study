# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a **JaCaMo** (Multi-Agent Oriented Programming) tutorial codebase from the 23rd European Agent Systems Summer School (EASSS23). It contains a series of progressive labs exploring the three dimensions of MAOP using a "Smart Room" scenario (temperature control via HVAC).

## Running Projects

Each lab sub-project is a standalone Gradle project. Run from within its directory:

```bash
cd lab1/smart-room-sa
./gradlew          # builds and runs (default task is 'run')
./gradlew build    # build only
./gradlew clean    # remove bin/, build/, log/
```

There are no shared tests — the system is verified by observation (console output, Mind Inspector, Organization Inspector).

To simulate a temperature change at runtime:

```bash
curl -X POST http://localhost:8080/workspaces/room/artifacts/hvac/properties/temperature \
  -H 'Content-Type: application/json' -d '[ 10 ]'
```

## Architecture

JaCaMo integrates three frameworks, each corresponding to a lab:

| Dimension                  | Framework                            | Lab        |
|:---------------------------|:-------------------------------------|:-----------|
| Agent (BDI reasoning)      | Jason (.asl files)                   | lab1, lab2 |
| Environment (artifacts)    | CArtAgO (Java classes in `src/env/`) | lab3       |
| Organisation (norms/roles) | Moise (XML in `src/org/`)            | lab4       |

### Project Structure Pattern

Every sub-project follows this layout:

```text
<project>/
  *.jcm              # MAS configuration: agents, workspaces, organisations, platform
  build.gradle       # Gradle build; main class is jacamo.infra.JaCaMoLauncher
  .jcm-deps.gradle   # Auto-generated dependency declarations from .jcm file
  src/agt/*.asl      # Jason agent programs (beliefs, goals, plans)
  src/env/           # CArtAgO artifact Java classes (lab3+)
  src/org/*.xml      # Moise organisational specification (lab4+)
  log/               # Runtime logs (created on run)
```

### Key Concepts

**`.jcm` file** — declares the MAS: which agents run which `.asl` programs, what workspaces/artifacts exist, what organisation is active, and which JaCaMo platform extensions to load (e.g., `JCMRest` on port 8080).

**`.asl` agent programs** — Jason syntax: beliefs are Prolog-like facts, goals are prefixed with `!`, plans are triggered by belief additions (`+belief`) or goal events (`+!goal`). Plans include `common-cartago.asl` and `common-moise.asl` templates via `include`.

**CArtAgO artifacts** — Java classes extending `Artifact`. Observable properties trigger belief updates in focused agents. Operations are callable from `.asl` via action names.

**Moise XML** — defines structural spec (groups/roles), functional spec (schemes/goals/missions), and normative spec (obligations/permissions).

## Lab Progression

- **lab1** — single agent (`room_controller.asl`) controlling HVAC; exercises on BDI reasoning
- **lab2** — multi-agent with message passing (performatives: `tell`, `signal`, `askOne`); exercises on a voting protocol via direct communication
- **lab3** — replaces message-based voting with a `VotingMachine` artifact; introduces CArtAgO observable properties, `focus`, artifact linking, and linked operations
- **lab4** — adds Moise organisation (`smart_house.xml`) with roles (`controller`, `assistant`), missions (`mController`, `mVote`), and a `decide_temp` scheme; exercises on organisational events (`oblFulfilled`, `goalState`)

## CNP Project (Practical Assignment)

The `cnp/` directory contains the practical assignment: a Contract Net Protocol simulation
with n initiators, m participants, and i parallel contracts per initiator.

### Running

```bash
cd cnp
./gradlew run           # single run with current cnp.jcm
```

JaCaMo does not self-exit — press `Ctrl+C` after the last `[DONE]` line appears.

### Experiment automation

```bash
cd cnp
python3 experiment.py                    # run full DEFAULT_MATRIX (6 configs)
python3 experiment.py --n 5 --m 10 --i 3  # single config
```

`experiment.py` generates `cnp.jcm`, runs JaCaMo with a 20s timeout, parses `[METRIC]`
lines, and prints a comparison table. Logs are saved to `cnp/results/`.

### Metrics

Initiators emit structured `[METRIC]` lines at contract end. Parse them with:

```bash
./gradlew run > run.log 2>&1
python3 metrics.py < run.log
```

### Key files

| File                          | Purpose                                         |
|:------------------------------|:------------------------------------------------|
| `cnp/cnp.jcm`                 | MAS config; edit to change n, m, i manually    |
| `cnp/src/agt/initiator.asl`   | CFP broadcast, winner selection, metric logging |
| `cnp/src/agt/participant.asl` | Price strategies, task simulation               |
| `cnp/experiment.py`           | Automated experiment matrix runner              |
| `cnp/metrics.py`              | `[METRIC]` line parser and summary printer      |
| `cnp/README.md`               | Full project documentation                      |

### Parameters

- **n** — number of initiators (add/remove `agent inX` blocks in `cnp.jcm`)
- **m** — number of participants (add/remove `agent paX` blocks)
- **i** — parallel contracts per initiator (length of `contracts([...])` list)
- Participant strategies: `random`, `fixed`, `aggressive`, `conservative`

## Tooling

- **Mind Inspector**: browser UI for inspecting agent beliefs/plans at runtime (launched automatically by JaCaMo)
- **Organization Inspector**: browser UI at `http://localhost:3171` for inspecting group/scheme state (lab4)
- **VSCode extension**: `jacamo4code` (redhat.vscode-xml for XML support) — see `.gitpod.yml` for versions
- **Java**: JDK 17+ required (Gitpod uses `17.0.6-tem`); JaCaMo version is `1.3.0` (see `build.gradle`)
