# Portability

Write for the shell you have, and say so. These bite silently elsewhere:

| BSD, so macOS-only            | Portable instead                      |
| ----------------------------- | ------------------------------------- |
| `sed -i ''`                   | `awk` to a temp file, then `mv`       |
| `date -j -f`                  | Compare ISO dates as text — they sort |
| `md5`                         | `shasum`, or drop the hash            |
| `awk '{print $1}'` over paths | `--porcelain` output, or whole lines  |

Bash is the floor. Windows needs WSL or Git Bash — say so in the skill that ships the script.

