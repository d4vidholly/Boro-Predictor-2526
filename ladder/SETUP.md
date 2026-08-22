# Boro Predictor — Supabase Setup Guide

Follow these steps once to get the backend live. Takes about 10 minutes.

---

## 1. Create a Supabase project

1. Go to [supabase.com](https://supabase.com) and sign up (free)
2. Click **New project**
3. Name it `boro-predictor`, pick a region close to the UK (e.g. West Europe), set a database password
4. Wait ~2 minutes for the project to spin up

---

## 2. Run the schema

1. In your Supabase project, go to **SQL Editor** (left sidebar)
2. Click **New query**
3. Open `schema.sql` from this folder, copy the entire contents, paste it in
4. Click **Run**

You should see: tables `waitlist`, `players`, `fixtures`, `predictions`, `results`, `settings` — plus the `ladder` view.

---

## 3. Get your API keys

1. In Supabase, go to **Settings → API**
2. Copy your **Project URL** (looks like `https://xxxx.supabase.co`)
3. Copy your **anon public** key (the long string under "Project API keys")

---

## 4. Paste keys into the site

Open each of these files and replace the two placeholder values near the top:

**`landing/index.html`**
```js
const SUPABASE_URL      = 'YOUR_SUPABASE_URL';   // ← paste here
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY'; // ← paste here
```

**`ladder/index.html`**
```js
const SUPABASE_URL      = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

---

## 5. Configure magic link redirect URL

1. In Supabase go to **Authentication → URL Configuration**
2. Set **Site URL** to:
   `https://d4vidholly.github.io/Boro-Predictor-2526/`
3. Under **Redirect URLs**, add:
   `https://d4vidholly.github.io/Boro-Predictor-2526/ladder/`
4. Save

---

## 6. GitHub Pages (already live)

- Repo: `https://github.com/d4vidholly/Boro-Predictor-2526`
- Landing page: `https://d4vidholly.github.io/Boro-Predictor-2526/landing/`
- Predictor: `https://d4vidholly.github.io/Boro-Predictor-2526/predict/`
- Ladder: `https://d4vidholly.github.io/Boro-Predictor-2526/ladder/`

---

## Day-to-day: entering results

Once matches are played, add results directly in Supabase:

1. Go to **Table Editor → results**
2. Click **Insert row**
3. Enter `fixture_index` (0–45, matches the order in `fixtures` table), `home_goals`, `away_goals`
4. Save — the `ladder` view recalculates automatically for all 24 players

> **Fixture index reference:** fixture 0 = Boro vs Lincoln City (15 Aug). See `predict/index.html`'s `fixtures` array for the full list.

**Which tables you can edit directly vs. need SQL for:**
- `results`, `settings`, `monthly_awards` — plain 1-row edits, just use Table Editor → Insert/Edit row directly, no SQL needed.
- `odds` — many rows per fixture, needs decimal-odds conversion and the Oddschecker column flip — ask Claude to write the upsert SQL for these rather than hand-entering in the grid.

---

## Locking predictions

The day before the first game, lock all predictions:

1. Go to **Table Editor → settings**
2. Find the row where `key = 'predictions_locked'`
3. Change `value` from `'false'` to `'true'`

The badge on the ladder page will update automatically.

---

## Future: wiring up a results API

When you're ready to automate result entry (instead of manual Supabase inserts):

- Use a Supabase **Edge Function** to poll the football API after each match
- The function inserts into the `results` table — the ladder view does the rest
- Recommended API: [football-data.org](https://www.football-data.org) (free tier covers Championship)

---

## Seat cap: 24 players

Supabase handles auth automatically but doesn't enforce a 24-player cap out of the box. When enough people have joined, you can either:

- Disable sign-ups in **Authentication → Settings → Disable sign ups**
- Or add a trigger to the `players` table that rejects inserts beyond 24 rows
