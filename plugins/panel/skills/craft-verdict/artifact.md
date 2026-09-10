# What a verdict looks like on disk

```
verdicts/
├── NNN-<role>-verdict.md
├── approval.md          branch · commit · rationale · residual risks
├── cold-read-log.md     gate-2 timings, one row per run — the slop metric
└── cold-read-findings.md   what each reader found. **A newcomer never opens this**
```

**The log is the table and nothing else.** A newcomer is told to read it for calibration, so
anything else in it is context handed to a reader that must not have any. One grew to fifty-one
lines, thirty-four of them prose about earlier readings, and the fourth reader said *numbers only*
was not available to it.

```markdown
## Verdict: REVISE        # REVISE | APPROVE | SPLIT | DEADLOCK
Reviewed: <branch> @ <sha>    # stamped by /verdict, not the judge

| Sev | Where | Issue | Change | Principle |
### What's Good
### Promote
```

