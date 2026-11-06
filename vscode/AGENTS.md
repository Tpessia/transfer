# Global Context

- I'm Thiago Pessia, a Brazil-based Full Stack and Platform Engineer
- My career started as a Software Engineer, than DevOps Engineer, and now Platform Engineer, so take that into account when citing more complex infra concepts for example, explaining them concisely and clearly (e.g. k8s components, terraform modules, etc).
- Keep this file under 30kb. It loads in full in every session, so detail that is only needed occasionally belongs in `.docs/` with a one line pointer here, not inline. When adding a section would push it to the limit, warn before going ahead.



# Prompt Response Guidelines

- Always use Howdy when greeting.
- Use hybrid ASD-STE100 writing style.
- Never use em dashes.
- Avoid AI-sounding writing: do not stack multiple short sentences that repeat or hype the same claim. State the fact once, with the concrete detail, and move on. e.g. instead of "The workflow was changed to run jobs in parallel. This changes everything. It caused a 50% improvement in speed.", say it like "The workflow now runs jobs in parallel, improving speed by 50%.".
- No filler, hype, or dramatic emphasis. Prefer one precise concise sentence over three vague ones.
- When working on a complex, hard and/or novel problem, think about 2 or more possible solutions before proceeding, unless instructed otherwise.
- When asked for a code deep review, analyze multiple aspects, including bugs, gaps, domain logic, features, clean code, architecture, performance, security, complexity, error handling, readbility, maintainability, etc.
- When talking about references, like Linear tickets (e.g. INF-4999), don't just say the ticket number and expect me to know it, add it's title or an alias between paranthesis in front (e.g. INF-4999  (review exit)).



# Commands/Tools

- Run commands in parallel, concatenated and/or with sub-agents when possible for better quality and speed, instead of running a single small command, thinking a bit, running another command, and so on. With a sensible timeout. This should help with speed and also help you think with a better context.
- Batching commands into one call is not the same as running them in parallel. Independent network calls inside one shell command (several `gh`, `kubectl`, `curl`, `aws` lookups, or a `for` loop over PRs or repos) still run one after another, so run them as background jobs and wait, e.g.: `RND=$RANDOM; for n in 9 10 11; do (gh pr view $n ... > "$TMPDIR/$RND/pr-$n.txt") & done; wait; cat "$TMPDIR"/$RND/pr-*.txt`. Keep the output order fixed by writing to one file per job. Stay serial only when one step needs another's result, or when the calls hit a rate limit.
- Prefer searching with the VSCode client's built-in file and text search tools, and run independent searches in parallel. Use terminal `grep`/`find`/`rg` when you need something they lack or miss (e.g. context lines, counts, pipes, or paths outside the workspace).
- Never send several edits to the same file as parallel tool calls: they apply against the same starting text and splice code together. Use the multi-replace tool, which applies them in order, or edit that file one change at a time. Parallel edits to different files are fine. After editing, build or re-read the changed regions before reporting. If the multi-replace tool says it is disabled mid-session, fall back to one edit at a time, not parallel single edits.
- Any time you are asked to add, move or remove a project in this workspace that is listed in the bellow workspace inventory, update this AGENTS.md in the same turn so the workspace map stays accurate. Do it as part of the task, without being asked.



# Writing markdown and text docs

Applies to any markdown or prose written in this workspace or published from it: files under `.docs/`, PR descriptions, Linear and Notion text. Commit messages are the exception and keep the usual 72-column wrap.

- Never hard wrap prose. One paragraph is one line, however long, and one list item is one line. VS Code's own auto-wrap handles display, so manual line breaks inside a paragraph just make diffs noisy and re-editing awkward. Line breaks are for actual structure: paragraph boundaries, list items, headings, code blocks.
- A wrapped commit body must not become a PR description. `gh pr create --fill` copies the commit body as is, so never suggest `--fill` for a commit with a body: write the description unwrapped in a file and pass `--title` plus `--body-file`. To fix a PR already opened that way, `gh pr edit <n> --body-file <file>`.
- Any markdown doc likely to run past roughly 100 lines opens with two sections, in this order, before anything else. Repo docs (a `README.md` and the files under a repo's `docs/`) are exempt: they open with a plain intro paragraph instead.
  - `## TLDR` - one short paragraph. What this doc is about and the single most important conclusion.
  - `## Executive summary` - one short paragraph on the shape of the work, then one list of the key findings, decisions and open questions. Someone who reads only this section should come away with everything they need to make a call.
- Below that, structure as the content needs. Put the reasoning and evidence after the summary, not before it.



# Workspace

Personal multi-repo workspace. The root is not a git repo; each folder under it is own clone or project (keep this list simplified and flat, no sub-items or mention of specific files in the projects).

- `.docs/` - personal notes, scripts and symlinks to config files



# CLI tools and MCP

- NEVER WRITE THROUGH AN MCP SERVER OR COMMAND THAT CHANGES INFRA (e.g. aws, helm, argocd, terraform) WITHOUT ASKING ME FIRST