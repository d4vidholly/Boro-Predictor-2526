# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Boro Predictor is a static web app for Middlesbrough FC fans to predict scores for all 46 fixtures in the 2026/27 EFL Championship season. It includes a multi-player prediction league backed by Supabase, with auth, a points ladder, and a waitlist landing page.

## Running the App

No build step or install required — open any HTML file directly in a browser. All external libraries load from CDN. There are no automated tests.

## Deployment

- **Live URL:** `https://www.boropredictor.com` (custom domain via GitHub Pages)
- **Repo:** `https://github.com/d4vidholly/Boro-Predictor-2526`
- **CNAME file** in repo root points GitHub Pages to `www.boropredictor.com`
- The root `index.html` immediately redirects to `landing/`
- All internal links use relative paths (`../dashboard/`, `../landing/`, etc.) — no hardcoded absolute URLs in any page

## Page Architecture

Six pages, each self-contained:

| File | Purpose |
|---|---|
| `landing/index.html` | Waitlist / sign-up landing page with Supabase email capture |
| `dashboard/index.html` | Home — shows next upcoming fixture + player's saved prediction |
| `predict/index.html` | Main predictor — all 46 fixtures, saves to Supabase |
| `ladder/index.html` | Live points ladder |
| `account/index.html` | Display name, club badge picker, prediction status, sign out |
| `analyst/index.html` | Personal stats hub — fan profile, community split, season summary (gated behind an intro modal) |

All pages except `landing/` require a Supabase auth session and redirect to `../landing/` if none is found.

## CSS Architecture

Four layers, applied in the same order on every page:

```html
<link rel="stylesheet" href="../assets/tokens.css">
<link rel="stylesheet" href="../assets/nav.css">
<link rel="stylesheet" href="../assets/app.css">
<link rel="stylesheet" href="styles.css">
```

| File | Scope |
|---|---|
| `assets/tokens.css` | Global reset, CSS custom properties (colours, fonts, `--nav-height`), Google Fonts import |
| `assets/nav.css` | Shared `.navbar` component |
| `assets/app.css` | Shared page chrome — `body`, `.page-title`, `.loading-state`, `footer`, `.dhd-logo`, `.copy` |
| `<page>/styles.css` | Page-specific styles — one file per page directory |

Each page directory (`dashboard/`, `predict/`, `ladder/`, `landing/`, `account/`, `analyst/`) has its own `styles.css`. There are no inline `<style>` blocks.

Design tokens (from `assets/tokens.css`): `--red`, `--red-dark`, `--black`, `--gold`, `--blue`, `--white`, `--off-white`, `--gray`, `--font-display` (Barlow Condensed), `--font-body` (Barlow).

## predict/index.html — Predictor App

All application logic is inline `<script>`.

### Data Model

- `fixtures` — 46 `{ home, away, date }` objects. Dates are placeholders pending the full schedule.
- `scores` — 46 `{ home, away }` objects; the only mutable state.
- `teams` — lookup from team name → badge SVG path in `assets/badges/`.

### Persistence

- `saveScoresToLocal()` / `loadScoresFromLocal()` — localStorage key `boroScores` (fast, offline)
- `savePredictions()` — upserts all 46 rows to the Supabase `predictions` table; also calls `saveScoresToLocal()`
- `loadPredictionsFromDB()` — loads from Supabase on auth init, falls back to localStorage if no DB rows exist

### Month Dividers

`renderFixtures()` uses a hardcoded index map to inject month header dividers between fixture cards:

```js
{ 0: 'August', 4: 'September', 8: 'October', 12: 'November',
  18: 'December', 24: 'January', 30: 'February', 35: 'March',
  39: 'April', 45: 'May' }
```

If fixtures are reordered, these indices must be updated manually.

### Key Functions

| Function | Purpose |
|---|---|
| `renderFixtures()` | Builds full fixture list DOM from `fixtures` + `scores` |
| `filterMonth(month)` | Shows/hides `.predictor` and `.month-divider` elements by `data-month` |
| `changeScore(index, team, delta)` | Mutates `scores`, clamps 0–9, saves to localStorage |
| `lockScoreButtonsIfPastDeadline()` | Disables all `.change-score` buttons once `PREDICTIONS_DEADLINE` has passed — nothing entered after that can be saved anyway |
| `renderPointsBanners(results)` | Post-deadline only: shows a bottom-of-card banner per fixture with a result — green (4pt exact), gold (1–3pt partial), dark red (0pt) |
| `calculatePoints()` | Tallies wins/draws/losses/GD, maps total points to one of 6 narrative tiers, opens report modal |
| `savePredictions()` | Upserts all predictions to Supabase `predictions` table |
| `submitPredictions()` | Exports predictions to `.xlsx` via XLSX CDN library |

### Season Outcome Tiers

`calculatePoints()` maps points totals to narrative outcomes: 100+ → "Smash the League", 75+ → promotion, 65+ → play-offs, 50+ → mid-table, 40+ → poor season, <40 → relegation nightmare.

### Scoring Rules

- Correct home goals: 1 pt
- Correct away goals: 1 pt
- Correct result (W/D/L): 1 pt
- Exact scoreline: 4 pts (replaces the above three, not in addition)

## Supabase Integration

- **Project ID:** `tkaayrdevanrozsbxmlv`
- All four authenticated pages share the same `SUPABASE_URL` and `SUPABASE_ANON_KEY` constants — hardcoded near the top of each page's `<script>` block. These are anon (public) keys, safe to expose client-side.
- `ladder/schema.sql` defines the full schema: `waitlist`, `players`, `fixtures`, `predictions`, `results`, `settings` tables plus a `ladder` VIEW that computes points using the same scoring rules as the JS app. RLS is enabled on all tables.
- Auth uses magic-link (`sb.auth.signInWithOtp`). A Postgres trigger (`handle_new_user`) auto-creates a `players` row on first login using the email prefix as the default name.
- Predictions are locked site-wide via `settings` table (`key = 'predictions_locked'`, `value = 'true'/'false'`). Dashboard and account pages both read this flag.
- **Waitlist** entries are visible in Supabase → Table Editor → `waitlist`.
- **Auth redirect URLs** in Supabase → Authentication → URL Configuration should include `https://www.boropredictor.com/**` and Site URL set to `https://www.boropredictor.com`.

See `ladder/SETUP.md` for the end-to-end setup guide (Supabase project creation, schema.sql, redirect URLs, and day-to-day result entry). Note: the URLs in that file still reference the old `github.io` path — the live domain is now `www.boropredictor.com`.

## account/index.html

Allows authenticated players to:
- Edit their display name (saved to `players.name`)
- Choose a club badge to represent them on the ladder (saved to `players.team_name`)
- View prediction lock status and count of fixtures predicted
- Sign out

## dashboard/index.html

Shows the next unplayed fixture — `getNextFixtureIndex()` finds the lowest `fixture_index` with no row in Supabase `results` yet (fixed 12 Aug 2026; was previously hardcoded to fixture 0 regardless of results, same approach as `analyst/index.html`'s `getNextFixture()`) — and the player's saved prediction for that match, read from `localStorage`. Uses the same `badges` map as the predictor page. Falls back to an "All Done" / Season Complete state once every fixture has a result.

## Assets

All assets live in `assets/`. Unused files are kept in `assets/_unused/` for reference.

- `assets/badges/` — SVG team logos for all 24 clubs (filename matches the team key used in `teams`/`badges` maps across pages).
- `assets/MoveClear.png` — footer logo linked from all pages.
- `assets/` — UI icons (`help.svg`), branding (`BoroPredictor.svg`, `DHD-logo.png`, `favicon.svg`).
- Outcome images — `boro-paper.webp`, `boro-promotion.webp`, `boro-playoffs.webp`, `boro-relegation.webp`, `boro-disaster.jpg` — used in the predict page's report modal.
