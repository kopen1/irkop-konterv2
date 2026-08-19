# AGENTS.md — konterv2

Baca terlebih dahulu: /root/workspace/AGENTS.md (aturan workspace global).

## Project Rules

- Project ID: konterv2
- Project Root: /root/workspace/projects/konterv2
- Mode: SOLO
- Teams: agent
- Satu Git repository di project root (/root/workspace/projects/konterv2/.git).
- JANGAN buat nested Git repository (git init) di dalam team-1/, team-2/, team-3/.
- Jalankan perintah git dari project root.

## Teams

Team directories BUKAN repository independen. Tidak boleh berisi .git,
.gitignore yang mengubah batas repository, atau .gitmodules.
