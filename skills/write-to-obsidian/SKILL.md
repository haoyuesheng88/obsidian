---
name: write-to-obsidian
description: Create, update, or append Markdown notes in the active local Obsidian vault on Windows. Use when Codex needs to send text into Obsidian, create a new note, append content to an existing note, write dated notes such as weather or schedules, or open the written note in Obsidian after saving.
---

# Write To Obsidian

Write the requested content into the user's active local Obsidian vault and keep the note path, title, and formatting practical for later retrieval.

## Workflow

1. Resolve the content before writing.
If the request depends on live information such as weather, news, schedules, or "today's" data, fetch that information first and use absolute dates in the note text.

2. Prefer the active vault.
Run [scripts/write-to-obsidian-note.ps1](scripts/write-to-obsidian-note.ps1). Let it discover the active vault from the local Obsidian config unless the user explicitly names another vault path.

3. Choose the note path deliberately.
When the user gives a target note or folder, use it directly.
When they do not, prefer a date-based filename or a short topic-based filename that matches the vault's existing style.

4. Avoid overwriting unrelated notes.
Use `-Append` only when the user asks to continue writing into an existing note or when appending is clearly safer than replacing.

5. Open the note after writing when helpful.
Use `-OpenInObsidian` when the user says "send to Obsidian", "open it", "write it into Obsidian", or similar.

6. Report the result briefly.
Tell the user which note was written. If the vault cannot be found or Obsidian is unavailable, say that clearly instead of pretending the write succeeded.

## PowerShell Usage

Create or replace a note:

```powershell
& 'C:\Users\QF100\.codex\skills\write-to-obsidian\scripts\write-to-obsidian-note.ps1' `
  -Title '2026-gaokao-date' `
  -Content $content `
  -OpenInObsidian
```

Write into a specific folder:

```powershell
& 'C:\Users\QF100\.codex\skills\write-to-obsidian\scripts\write-to-obsidian-note.ps1' `
  -RelativePath 'weather/2026-04-13-shanghai-fengxian.md' `
  -Content $content `
  -OpenInObsidian
```

Append to an existing note:

```powershell
& 'C:\Users\QF100\.codex\skills\write-to-obsidian\scripts\write-to-obsidian-note.ps1' `
  -RelativePath 'journal/today.md' `
  -Content $extra `
  -Append `
  -OpenInObsidian
```

## Formatting Notes

For short facts, prefer a compact title plus a short paragraph or flat bullet list.

For date-sensitive notes, include the full date in both the filename and body when practical.

Keep Markdown simple unless the user asks for a richer template.

## Failure Handling

If no Obsidian vault can be discovered, stop and tell the user the local Obsidian config did not expose an active vault.

If the write succeeds but the `obsidian://` open action fails, report that the file was still saved locally.
