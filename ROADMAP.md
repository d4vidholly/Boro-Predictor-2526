# Boro Predictor — Roadmap & Feature Ideas

## Key Dates

| Date | Milestone |
|---|---|
| ✅ ~Mid June 2026 | EFL Championship 2026/27 fixtures released |
| ✅ 25 June 2026 | Fixture data live, predictor page open |
| 14 August 2026 | Season starts — predictions locked |

---

## Phase 1 — Fixture Data ✅ Complete

- ✅ EFL released 2026/27 Championship fixtures 25 June 2026
- ✅ 24 teams confirmed — 6 new teams in (Bolton, Burnley, Cardiff, Lincoln, West Ham, Wolves); 6 out (Coventry, Hull, Ipswich, Leicester, Oxford Utd, Sheff Wed)
- ✅ Placeholder badges created for all 6 new teams in `assets/badges/` — replace with official SVGs before launch
- ✅ `predict/index.html` — fixtures array updated with all 46 real dates, teams map and SHORT_NAMES updated, month divider index map recalculated
- ✅ `dashboard/index.html` — same fixtures, teams map, and SHORT_NAMES updated to match
- ✅ Stadium added to each fixture (Riverside Stadium for home, real away ground names confirmed)
- ✅ Kick-off times added where confirmed (8 fixtures); rest show TBC pending TV selections
- ⬜ Upsert real fixture dates into Supabase `fixtures` table (currently DB has placeholder dates — not blocking for launch but needed for `dashboard` next-fixture logic to work correctly)
- ⬜ Replace placeholder badges with official SVGs for Bolton, Burnley, Cardiff, Lincoln, West Ham, Wolves
- ⬜ Update remaining kick-off times as Sky Sports confirms TV picks (typically 4–6 weeks out)

## Phase 2 — Open the App (now → August 14)

- ✅ Login model decided: **invite-only**. `shouldCreateUser: false` on magic-link sign-in — only emails already in the auth DB can log in. Admin sends the first-time link manually once payment is confirmed.
- ✅ Magic-link flow tested and hardened (see Admin Tool + Recent Changes below)
- ⬜ Confirm `predictions_locked = false` in Supabase settings table
- ⬜ Confirm Supabase auth redirect URLs include `https://www.boropredictor.com/**`
- ⬜ Invite paid players via the new admin tool (see below)
- ⬜ Re-enable auth redirects on `dashboard/index.html` once invite flow is confirmed working end to end (currently commented out — `// TODO: restore auth redirect when sign-in flow is wired up`)

## Admin Tool (new, uncommitted)

`admin/index.html` + `admin/styles.css` — built but not yet committed to git.

- Passphrase-gated page (not linked from nav, `noindex,nofollow`)
- Lets David send a first-time magic-link sign-in to a player's email once their payment is confirmed
- Keeps a "sent this session" list for tracking
- ⬜ Decide on the passphrase / auth approach before this goes live (currently a client-side passphrase check — fine for now but worth hardening before relying on it)
- ⬜ Commit `admin/` to the repo (currently untracked)

## Recent UI Changes (7 August 2026)

**Security**
- Fixed auth bypass: `dashboard/`, `predict/`, `ladder/`, `account/`, `analyst/` were all reachable without logging in (redirect was missing or commented out on every gated page) — all five now redirect to `../landing/` when there's no session. A localhost/`file://`-only dev bypass was added to `predict/` and `analyst/` so they're still testable without redeploying, but it never applies on the live domain.
- Fixed ladder RLS: `players` table only allowed each player to read their own row, which silently collapsed the `ladder` view down to one row per viewer. Replaced with a broad authenticated-read policy (`players_select_all`), matching the pattern already used for `predictions`/`fixtures`/`results`/`settings`.
- Fixed stale `fixtures` table data: Supabase still had the old placeholder schedule (fixture 0 = Middlesbrough vs Swansea City) while `predict/index.html` had since been updated with the real 2026/27 fixtures (fixture 0 = Middlesbrough vs Lincoln City, 15 Aug). Corrected all 46 rows in place; `predictions`/`results` were unaffected since they only reference `fixture_index`, not team names.

**Predict page**
- Deadline countdown ticker added (gold/black), counting down to 00:00 15/8/26 GMT
- Month tabs no longer hide fixtures — all 46 always shown; tabs now jump-scroll to that month's section, and the active tab updates via scroll position (based on the first fully-visible fixture card) as the user scrolls manually
- "Report" button renamed to "Article"; Gazette date updated to May 2027
- Season report copy updated: manager references changed to Kim Hellberg, "top six" → "top eight", em-dashes removed from one line

**Badges**
- Fixed broken "Away" badge (pointed at a missing `overland.svg`; now points to `away.svg`)
- Added three new badges: Dickens Away, Dickens Home, Midnite Blue

**Analyst page** — see "Analyst Page — Current Build" section below for full detail. Summary: Community Split and Most Common Score are now fully live with per-team colours/badges and "you predicted" reminders; Bookies is wired end-to-end but blocked on the odds cron; everything except the first two panels is blurred or hidden behind a "More features coming soon" overlay; the full gate modal is temporarily disabled for review (needs restoring before shipping).

**Dashboard**
- Prediction card upgrade prompt: dropped the "Premium" label, reworded to "See what everyone else is predicting", CTA changed from "Upgrade" to "Analyst Mode"

## Recent UI Changes (6 August 2026)

**Login / auth**
- Landing page converted from waitlist email capture to a magic-link login form ("Get my link")
- Switched to invite-only: `shouldCreateUser` fixed from `false`→`true`→back to `false` over the day; final state is invite-only (admin sends first link)
- Fixed session race condition: `predict/index.html` now also listens via `onAuthStateChange` as a fallback so the session is reliably captured after the PKCE redirect from a magic link
- Error handling: button resets to "Get my link" (not "Log In") on failure, with a clearer error message
- Auth redirects removed from `predict/` and `dashboard/` for now — pages are accessible without login while the invite flow is being finished; `account/` and sign-out still redirect to landing

**Badges & ladder**
- Account page: Team Information card with a clickable badge icon opening a modal of 5 SVG icon choices; badge now saved to `players.team_name` in Supabase (survives logout/login), not just localStorage
- Ladder: club badge now shown per row (reads `team_name`), sized to match the fallback grey circle, with a fallback if the badge ID isn't recognised

**Other UX**
- Predict page: save button stays on "Saved ✓" until the next edit instead of resetting after 1.2s
- Predict page: unsaved-changes warning if the user navigates away or closes the tab with edited-but-unsaved scores
- All pages: logo now links to `dashboard/` instead of `landing/`
- Account page: contact email section added then removed same day (not ready yet)
- All pages: footer disclaimer added — not affiliated with Middlesbrough FC
- Analyst gate modal: title changed to "Coming Soon", Enter button and dismiss handlers removed (gate is now permanent, not skippable)
- Colour tokens updated: `--red` → `#F8444A`, `--gold` → `#F2D054`, navbar `--brand-dark` → `#F71538`
- Predict/dashboard: match cards show stadium and kick-off time
- Landing page step images (`landing-a/b/c.png`) refreshed

## Other Untracked Files

- `Boro_Predictor_Accessibility_Audit.docx` sitting in repo root, untracked — a WCAG audit doc, worth deciding whether it belongs in the repo (e.g. move to a `/docs` folder) or just kept locally.

## Phase 3 — Lock & Run (August 14 onwards)

- Set `predictions_locked = true` before kickoff
- Enter results weekly via `ladder/SETUP.md` flow
- Ladder VIEW auto-computes points

---

## Waitlist / Non-Entrants

Users who sign up on the landing page but never enter the competition sit only in the `waitlist` table. Plan:

- Add **"keep me updated"** opt-in checkbox to landing form (separate GDPR consent from competition entry)
- Newsletter has two audiences:
  - **Players** — full results, ladder, standings, Manager of the Month
  - **Waitlist** — lighter version ("here's this week's results, join the league next season")
- Resend supports multiple audience lists for clean segmentation

---

## Analyst Page — Current Build (updated 7 Aug 2026)

Six panels on `analyst/index.html`. Only the first two are finished and visible; everything else is blurred or hidden behind a "More features coming soon" overlay so the page can be shown without looking half-built.

- ⬜ **The full-page "Coming Soon" gate modal is currently disabled** (commented out in the HTML, `<!-- ANALYST GATE MODAL (temporarily disabled for review...) -->`) so it could be worked on locally. A lighter gold "In development" banner is shown instead. **Restore the gate modal before real players are pointed at this page** — right now anyone who navigates here directly sees the live panels below, not a blocking wall.

### Panel 1 — Community Split ✅ Live
**What:** Donut chart showing how the community split their prediction (home win / draw / away win) for the next unplayed fixture.

- Shares one `predictions` query with Most Common Score via a common `getNextFixture()` helper (lowest `fixture_index` with no `results` row — resilient to `match_date` still being mostly `NULL`)
- Home/away badges pinned to the left/right edges of the fixture header line; team names centred between them
- Key rows use colour-coded dots (not badges) — Draw stays neutral grey
- Donut segments + dots use a per-team `TEAM_COLORS` map: Boro is always app-red, other traditionally-red clubs (Bristol City, Charlton, Sheffield United, Southampton, Stoke, Wrexham) got substitute colours so they don't clash with Boro; Lincoln City is black
- "You predicted: [winner/Draw]" reminder at the bottom, reading the player's own saved localStorage prediction
- Handles zero-predictions and season-complete states

### Panel 2 — Most Common Score ✅ Live
**What:** The exact scoreline most players predicted for the next fixture, and what % called it.

- Bar fill colours to whichever side the scoreline favours (home/away team colour, or a darker grey `#767B85` for a draw — distinct from the pale bar-track grey)
- "You predicted: [score]" reminder at the bottom

### Panel 3 — Fan Profile ✅ Live (blurred)
**What:** Classifies the player as Pessimist / Realist / Optimist based on their own predicted Boro season points total vs actual results so far.

**Thresholds:** 🌧️ Pessimist <50 pts · 🔬 Realist 50–74 pts · ☀️ Optimist 75+ pts

Currently sits behind the blur overlay along with Bookies — functionally complete, just not part of the public-facing set yet.

### Panel 4 — Bookies Probability — built, blocked on external data (blurred)
**What:** Implied probability of the player's own predicted scoreline based on betting market odds. Colour coded: <5% Long Shot · 5–10% Possible · 10–15% Decent · 15%+ Strong.

- `odds` table + RLS created in Supabase (SELECT-only for authenticated users)
- `supabase/functions/sync-odds/index.ts` — finds the next fixture, matches it on The Odds API, pulls `correct_score` odds for a single fixed UK bookmaker (bet365, falls back to first available), upserts into `odds`
- Deployed and manually invoked successfully — key valid, event matching works, frontend reads from `odds` and applies the colour tiers correctly
- ⬜ **Daily cron not yet scheduled** — creating it in Dashboard → Integrations/Cron failed with `42P01: relation cron.job does not exist` because the `pg_cron` extension isn't enabled. Fix: Database → Extensions → enable `pg_cron`, then recreate the cron job (Type: Supabase Edge Function → `sync-odds`, schedule `0 8 * * *`, Authorization header with the anon key, timeout 5000ms — cron job fields already filled in once, just needs pg_cron enabled first)
- ⬜ The `correct_score` market isn't yet covered by The Odds API for the next fixture (Middlesbrough v Lincoln, 15 Aug) even though it's live on Oddschecker — likely an ingestion lag on The Odds API's side, not a bug. Re-check closer to kickoff once the cron is running.

### Panels 5 & 6 — Season Achievement / Your Season — hidden entirely
Both fully commented out in the HTML (not just blurred) until Season Achievement is ready to build. "Your Season" was previously live (season points/outlook summary from localStorage) but is switched off along with Season Achievement for now — re-enable both together.

**Season Achievement (not yet built):** The player's rarest correct prediction — the scoreline they got right that the fewest other players also got right.
- Requires results to be entered in `results` table
- Query: join `predictions` + `results` to find player's correct exact-score predictions
- For each correct prediction, count how many other players predicted the same scoreline
- Surface the one with the lowest count (rarest)
- Display: "Boro 3–1 Derby · Only 2 players called this · Your rarest call"

---

## Premium Analyst Mode

**Pricing:** $3/month or $20/season (all 10 monthly skins guaranteed)

Predictions are locked before the season so no pay-to-win. Premium is purely cosmetic + insight.

### Feature Ideas

1. **Monthly Boro skins** — limited drops, e.g. retro kits, iconic eras (Juninho 96/97, Riverside opening). Only active subscribers unlock them. Creates FOMO and a collectible angle.

2. **Community prediction split** — per fixture, before kickoff: 64% home / 22% draw / 14% away. Flips to show actual result after the match.

3. **Bookies vs community overlay** — implied probability from odds (The Odds API) shown alongside what your league predicted. Highlights where the crowd diverges from the market.

4. **Historical H2H facts** — "Boro haven't won at Elland Road since 2012" auto-surfaced on each fixture card. Start with a static dataset, enrich via football-data.org API.

5. **Personal accuracy breakdown** — "You're great at predicting Boro home wins (78%) but terrible away (22%)." Season-long stat card, updates live.

6. **Head-to-head mode** — challenge another player, track who wins each gameweek between you two.

7. **Season trajectory graph** — your points over time vs league average. Basic chart visible to all; detailed drill-down is premium.

8. **Predicted final table** — aggregate all community predictions into a consensus Boro finish position.

9. **Monthly newsletter + Manager of the Month** — top points scorer that calendar month gets the award. Sent to all premium subscribers.

10. **Prediction badges / achievements** — cosmetic, shareable, premium-only. See achievements section below.

---

## Predictor Profile

Based on two axes plotted across the season:

- **Confidence** — how many goals do they predict vs actual average scorelines
- **Optimism** — how often they back Boro vs how Boro actually perform

### Archetypes

| Type | Description |
|---|---|
| **The Romantic** | Always backs Boro, always high-scoring games, perpetually wrong |
| **The Realist** | Tracks the form, picks with head not heart |
| **The Doomer** | Expects the worst, occasionally a genius |
| **The Tactician** | Brilliant at results, terrible on exact scores |
| **The Optimist** | Upgrades every Boro performance by exactly one goal |

Profile card lives on the account page. Shareable as an image. Updates live as predictions vs results accumulate through the season.

---

## Achievements

Earned badges displayed on the ladder (player chooses which to show if they hold multiple). Starts empty — fills as the season progresses.

### Rarity Tiers

**Common** — most players will earn these

| Badge | Trigger |
|---|---|
| **Founder** | Sign up for season 25/26 |
| **Strong Start** | Correct result in first game of the season
| **Manager of the Month** | Win manager of the month award |
| **Off the Mark** | Correct scoreline on any match |
| **Optimist** | Predict Boro get more points than they actually do |
| **Realist** | Predict Boro get within 10 points than they actually do |
| **Mystic** | Predict Boro get the exact number of points |
| **Pessimist** | Predict Boro get less points than they actually do |
| **Champion** | Come first in the final table |
| **Promoted** | Come Second in the final table |
| **Play offs** | Come third, fourth, fifth or sixth in the final table |
| **Relegated** | Finish 22nd, 23rd or 24th in the final table |
| **Full House** | Correct scoreline on Boxing Day |
| **Eye Spy** | Correct scoreline v Southampton |
| **Loyal Supporter** | Upgrade to the Analyst Tier |


*More to be added...*

### Schema (additions needed)

```sql
-- Achievement records
CREATE TABLE public.achievements (
  id         SERIAL PRIMARY KEY,
  player_id  UUID REFERENCES public.players(id) ON DELETE CASCADE,
  badge_key  TEXT NOT NULL,
  earned_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Active display badge on ladder
ALTER TABLE public.players ADD COLUMN display_badge TEXT;
```

Ladder VIEW joins on `display_badge` to show chosen badge per row.

---

## Ladder Display

Each row: **Rank / Club badge / Name / Achievement badge / Points**

Achievement badge slot is empty until earned. Once multiple badges are held, player picks which to display from account settings.

---

## Newsletter Stack

- **Brevo** — chosen tool. Free at current scale (~50 users). HTML editor, unsubscribe handling, audience segmentation, and native Supabase integration to sync `waitlist` and `players` tables as separate audiences.
- ⬜ Set up Brevo account and verify `boropredictor.com` sending domain
- ⬜ Connect Supabase → Brevo: sync `waitlist` table as one audience, `players` table as another
- ⬜ **Wireframe the email layout** before building in Brevo — long-scroll HTML email with custom background, Boro Predictor branding (red/black, Barlow Condensed), badge/imagery blocks

### Email Sequence

| # | Email | Audience | Timing |
|---|---|---|---|
| 1 | Fixtures are out — here's the link, forward to mates | Waitlist | Now |
| 2 | Site is live — sign up and lock in your predictions | Waitlist | Once auth flow verified |
| 3 | Analyst tier — here's what you get | Players | Mid-July |
| 4 | One week to go — predictions close Aug 14 | Players | ~Aug 7 |
| 5 | Final hours — lock in tonight | Players | Aug 13 |
| 6 | We're live — first results coming | Players | Aug 14 |
| 7 | Weekly newsletter | Players | Every Monday in-season |

### Weekly Newsletter (in-season)
- Supabase Edge Function — scheduled weekly, queries `results` for that week's scores + `ladder` for standings, posts to Brevo API
- `newsletter_opt_in BOOLEAN DEFAULT TRUE` column on `players` table
- Subscription toggle in `account/index.html`
