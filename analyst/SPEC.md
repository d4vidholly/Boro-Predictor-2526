# Analyst Panels — Spec: Community Split & Points Projection (Bookies)

Status: draft, for post-deadline build (predictions lock 14 Aug 2026)

---

## 1. Community Split

**What it shows:** how the league split their prediction for the next Boro fixture — home win / draw / away win — as a donut chart.

**Where it lives:** `analyst/index.html`, panel 1 ("Community Split"). Currently hardcoded to 58/25/17 for Boro vs Swansea — not wired to real data.

**Related, already-built panel:** `analyst/index.html` also has a "Most Common Score" panel that already queries `predictions` for `fixture_index = 0` and computes the most common exact scoreline + %. It's live but hardcoded to fixture 0. Community Split should reuse the same query and the same "next fixture" logic — no need to fetch predictions twice.

### Data source
`predictions` table, no schema changes needed. Existing RLS policy `predictions_select_all` already allows any authenticated user to read all predictions — no policy change required.

### Determining "next fixture" (the real blocker)
Both panels are currently hardcoded to `fixture_index = 0`. To move to fixture 1, 2, 3... as the season progresses, we need a reliable "what's the next unplayed fixture" query. Two options:

- **By `match_date`** — pick the earliest fixture with `match_date >= today`. Blocked today: per `ROADMAP.md` Phase 1, only fixture 0 has a real date in the `fixtures` table; fixtures 1–45 are still `NULL`. This needs the real fixture dates upserted first (already an open roadmap item).
- **By `results`** — pick the lowest `fixture_index` with no row in `results` yet. Since Boro's fixtures are already stored in strict chronological order (`fixture_index` 0→45 = season order), this works today without waiting on real dates, and stays correct automatically once results start being entered weekly.

**Recommendation:** use the `results`-based approach. It removes the dependency on the Phase 1 fixture-dates task and will keep working unattended all season.

```sql
-- Pseudocode for "next fixture"
SELECT MIN(f.fixture_index)
FROM fixtures f
LEFT JOIN results r ON r.fixture_index = f.fixture_index
WHERE r.fixture_index IS NULL;
```

### Logic
1. Get next fixture index (above).
2. Query `predictions` where `fixture_index = <next>`.
3. Classify each row: `home_goals > away_goals` → home win, `<` → away win, `=` → draw. (Flip home/away if Boro are away — reuse the `BORO_HOME` lookup already in the page.)
4. Count and convert to %.
5. Render into the existing donut + key markup (`cs-donut`, `.cs-dot-h/d/a`, percentage text).
6. Pull the fixture label (team names) from the `fixtures` table row for that index instead of the hardcoded "Middlesbrough vs Swansea City".

### Edge cases
- **Zero predictions for the fixture** — show "No predictions yet" rather than a 0/0/0 donut (avoid divide-by-zero).
- **Small sample (current: 3 players)** — the split will be blocky and will jump a lot with each new entrant. Suggested treatment: show a small "(n predictions so far)" caption under the donut so it reads as directional, not final. No technical blocker either way — this is a display decision, not a build one.
- **All fixtures played (season over)** — "next fixture" query returns no rows; panel should show a season-complete state rather than erroring.

### Effort
Small — this is a JS/query change to an existing page, reusing patterns already proven by the live "Most Common Score" panel. No new tables, no new RLS policies, no external API.

---

## 2. Points Projection (Bookies)

**What it shows:** the implied probability of the player's own predicted scoreline for the next fixture, based on bookmaker odds. Colour-coded: <5% Long Shot (red), 5–10% Possible (amber), 10–15% Decent (blue), 15%+ Strong (green).

**Where it lives:** `analyst/index.html`, panel labelled "Bookies". Currently shows the player's saved prediction (from localStorage) but the probability is a static "—" / "Odds API coming soon" placeholder.

**Your stated constraint:** odds exist for multiple fixtures and change over time — you don't want to type them in by hand. That means odds must be **fetched and cached automatically**, not entered anywhere in the UI by David.

### Why odds can't just be called from the browser
Correct-score odds come from a third-party odds API that requires a private API key. Calling it directly from `analyst/index.html` would expose that key to anyone who views page source, and would mean every visitor's page load burns an API credit — with 24 players refreshing repeatedly, that blows through any free-tier budget fast. The odds need to be fetched **once, server-side, and cached** — the page then just reads from Supabase like everything else.

### Recommended data source: The Odds API
Confirmed via their current docs (Aug 2026):
- English Championship is a supported sport: sport key `soccer_efl_champ`, with scores/results support.
- `correct_score` ("Correct Score at Regulation Time") exists as a market, under their "additional/other soccer markets" — fetched per-event via `/v4/sports/soccer_efl_champ/events/{eventId}/odds?markets=correct_score&regions=uk`, not the plain `/odds` list endpoint.
- Caveat directly from their docs: "coverage of non-featured markets is currently limited to selected bookmakers and sports, and expanding over time" — so correct-score odds are not guaranteed to exist for every Championship fixture, especially lower-profile ones. The panel needs a graceful "not available for this fixture yet" fallback rather than assuming it's always there.
- Free tier: 500 credits/month, no card required. A `correct_score` pull with one region costs roughly 1 credit per call (cost = markets × regions). Fetching odds for one upcoming Boro fixture once a day in the few days before kickoff should sit comfortably inside the free tier across a season — this is a rough estimate, worth sanity-checking against their live pricing page once you're building, not just this spec.
- You (David) need to sign up for a free API key once — that's the only "manual" step, and it's one-time, not per-match.

### Architecture — where the odds actually get typed in / stored

**Nowhere by hand. The pipeline is:**

1. **New Supabase table `odds`** — this is what the frontend reads. No client ever writes to it directly.
   ```sql
   CREATE TABLE public.odds (
     id            SERIAL PRIMARY KEY,
     fixture_index INTEGER NOT NULL REFERENCES public.fixtures(fixture_index),
     home_goals    INTEGER NOT NULL,
     away_goals    INTEGER NOT NULL,
     decimal_odds  NUMERIC(6,2) NOT NULL,
     bookmaker     TEXT,
     fetched_at    TIMESTAMPTZ DEFAULT NOW(),
     UNIQUE(fixture_index, home_goals, away_goals)
   );

   ALTER TABLE public.odds ENABLE ROW LEVEL SECURITY;
   CREATE POLICY "odds_select" ON public.odds
     FOR SELECT USING (auth.role() = 'authenticated');
   -- No insert/update policy for regular users — only the service-role
   -- key (used by the Edge Function below) can write to this table.
   ```

2. **Supabase Edge Function** (e.g. `sync-odds`), scheduled via `pg_cron` or Supabase's built-in cron trigger — same mechanism already planned for the weekly newsletter function in the roadmap. Runs on a schedule (e.g. daily, or twice daily in the 48h before kickoff):
   - Looks up the next unplayed fixture (same query as Community Split above).
   - Calls The Odds API's events endpoint for `soccer_efl_champ` to find the matching event ID (match by team names / kickoff date).
   - Calls the event odds endpoint with `markets=correct_score&regions=uk`.
   - Parses the response and upserts one row per scoreline outcome into `odds` (on conflict update `decimal_odds`, `bookmaker`, `fetched_at`).
   - The Odds API key lives as an Edge Function secret — never shipped to the browser.

3. **Frontend change** — `analyst/index.html`'s Bookies panel queries `odds` for the current fixture, finds the row matching the player's own saved prediction (`home_goals`/`away_goals` from localStorage), and computes:
   ```
   implied_probability = 100 / decimal_odds
   ```
   Then applies the existing colour-tier logic (already speced: <5/5–10/10–15/15+%).

### Edge cases
- **No odds row matches the player's exact scoreline** (e.g. they predicted 6–1, bookies don't quote it) — show something like "Scoreline not covered by the odds market — vanishingly rare" rather than blank/error.
- **Odds not yet fetched for this fixture** (Edge Function hasn't run yet, or `correct_score` market unavailable for this match) — fall back to the current "Odds coming soon" state, not a broken UI.
- **Multiple bookmakers returned** — decide once: use a single reference bookmaker consistently (simplest, matches what one book actually pays), or average across available UK books (smooths outliers but adds a step). Recommend starting with a single fixed bookmaker for simplicity, revisit if odds look inconsistent.

### Effort
Medium — this is the one with real new infrastructure: a new table, RLS policy, and a scheduled Edge Function with a third-party API key. The frontend read-and-display part is small once the table exists.

### Open decisions before building
1. Confirm The Odds API as the source (vs. an alternative odds provider) and get a free API key.
2. Pick fetch cadence (daily vs. twice-daily near kickoff).
3. Single bookmaker vs. averaged odds.
4. Confirm the Edge Function scheduling mechanism you want to use (Supabase already needs this for the newsletter — worth building the "scheduled Edge Function" pattern once and reusing it for both).
