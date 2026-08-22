# What a verdict looks like on disk

```
verdicts/
├── NNN-<role>-verdict.md
├── approval.md          branch · commit · rationale · residual risks
└── cold-read-log.md     gate-2 timings, one row per run — the slop metric
```

```markdown
## Verdict: REVISE        # REVISE | APPROVE | SPLIT | DEADLOCK
Reviewed: <branch> @ <sha>    # stamped by /verdict, not the judge

| Sev | Where | Issue | Change | Principle |
### What's Good
### Promote
```

