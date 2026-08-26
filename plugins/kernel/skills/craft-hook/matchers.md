# SessionStart matchers

SessionStart fires on multiple sources. Use matchers to control when:

```json
{
  "matcher": "startup|resume|clear",
  "hooks": [{ "command": "remember.sh" }]
}
```

| Matcher   | When                                |
| --------- | ----------------------------------- |
| `startup` | New session                         |
| `resume`  | `--resume`, `--continue`, `/resume` |
| `clear`   | `/clear`                            |
| `compact` | After context compaction            |

