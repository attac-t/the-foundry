# Map: Examples

Patterns for elegant directory trees.

---

## Plugin Structure

```
craftsman/                        # Cognitive Operating System
├── agents/                       → sub-agent personas
│   ├── architect.md              → leads, delegates
│   └── reviewer.md               → ruthless critic
│
├── commands/                     → user triggers
│   ├── blueprint.md              → load plan
│   └── ...                       → 3 more
│
├── hooks/                        → automatic reflexes
│   ├── anchor.sh                 → echo objective
│   ├── recite.sh                 → load memory
│   └── ...                       → 5 more
│
├── skills/                       → domain knowledge (37)
│   ├── craft-*/                  → creation patterns
│   ├── decide-*/                 → decision frameworks
│   └── ground-*/                 → cognitive protocols
│
└── tests/                        → verification
    └── *.yml                     → 64 atomic tests
```

**Summary:**

| Layer    | Count | Purpose   |
|----------|-------|-----------|
| Agents   | 2     | Personas  |
| Commands | 4     | Triggers  |
| Hooks    | 7     | Reflexes  |
| Skills   | 37    | Knowledge |

---

## Collapsed Repetition

```
skills/
├── craft-handler/                ┐
├── craft-resource/               │ creation (16)
├── craft-test/                   ┘
├── decide-extraction/            ┐
├── decide-events/                ┘ decisions (11)
└── ground-*/                        protocols (8)
```

---

## With Depth Limit

```
src/                              # depth: 2
├── components/
│   └── ...
├── services/
│   └── ...
└── utils/
    └── ...
```
