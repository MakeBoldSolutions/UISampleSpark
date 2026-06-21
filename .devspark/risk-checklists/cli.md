# CLI Risk Checklist

## Process Contract

- [ ] **Documented exit codes** (0 success, distinct non-zero for user error vs internal error vs timeout)
- [ ] **SIGINT / SIGTERM handled** with graceful cleanup (temp files, child processes)
- [ ] **SIGPIPE tolerated** when piping into `head`, `less`, etc. (no broken-pipe stack traces)

## I/O Discipline

- [ ] **Machine-readable output on stdout, human/diagnostic on stderr**
- [ ] **Structured output mode** (`--json` / `--format`) for scripting
- [ ] **stdin honored** when input is piped (no interactive prompt that blocks pipelines)
- [ ] **Color disabled when stdout isn't a TTY** (`NO_COLOR`, `--no-color`, isatty detection)

## Cross-Platform

- [ ] **Paths use platform-appropriate separators and case rules** — e.g., `pathlib`, `filepath`, `Path` APIs
- [ ] **Encoding explicit (UTF-8) on file and stream I/O**
- [ ] **Long-path / reserved-name handling on Windows** (CON, NUL, paths >260 chars)

## UX & Safety

- [ ] **`--help` and `--version` always work, even without subcommand**
- [ ] **Destructive operations require confirmation or `--yes`**
- [ ] **Dry-run mode** for any command that mutates external state
- [ ] **Shell-completion scripts shipped** — e.g., bash/zsh/fish/PowerShell
