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

- ⬜ Verify magic-link → player creation → predict → save flow end to end (testing in progress)
- ⬜ Confirm `predictions_locked = false` in Supabase settings table
- ⬜ Confirm Supabase auth redirect URLs include `https://www.boropredictor.com/**`
- ⬜ Invite waitlist users

## Recent UI Changes (August 2026)

- Auth redirects removed — all pages accessible without login; Supabase features degrade gracefully
- Colour tokens updated: `--red` → `#F8444A`, `--gold` → `#F2D054`, navbar `--brand-dark` → `#F71538`
- Predict page: match cards now show stadium and kick-off time
- Dashboard: upcoming fixture shows kick-off time and stadium
- Analyst gate modal title changed to "Coming Soon"
- Account page: badge picker redesigned — 5 custom SVG icons in Team Information card, clicking the icon opens a modal to choose; display name and badge persist via localStorage

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

## Analyst Page — Current Build

Four panels on `analyst/index.html`. Gate modal on entry. Fan Profile is live (reads localStorage); others connect to data as it becomes available.

### Panel 1 — Community Split
**What:** Pie/donut chart showing how the 24-player community split their prediction for the next fixture (home win / draw / away win).

**Current state:** Placeholder percentages (58% / 25% / 17%) hardcoded for Boro vs Swansea.

**To make live:**
- Query `predictions` table for fixture index 0 (next match), count predicted outcomes per player
- Determine each player's predicted result (Boro win / draw / loss) from their scoreline
- Calculate percentages and re-render the conic-gradient donut dynamically
- Update fixture label from `fixtures` table or hardcoded array

### Panel 2 — Bookies Probability
**What:** Shows the implied probability of the player's own predicted scoreline based on betting market odds. Colour coded by chance: <5% Long Shot · 5–10% Possible · 10–15% Decent · 15%+ Strong.

**Current state:** Shows player's saved prediction for fixture 0 (from localStorage). Probability shows "—" with "API coming soon" label.

**To make live:**
- Integrate The Odds API (or API-Football odds endpoint)
- For each upcoming fixture, fetch correct-score market odds
- Convert decimal odds to implied probability: `1 / decimal_odds * 100`
- Match against player's predicted scoreline and display
- Cache results (odds rarely change more than once/day)
- Threshold colours: <5% → red `.prob-long` · 5–10% → amber `.prob-poss` · 10–15% → blue `.prob-decent` · 15%+ → green `.prob-strong`

### Panel 3 — Fan Profile
**What:** Classifies the player as Pessimist / Realist / Optimist based purely on their own predicted Boro season points total.

**Current state:** ✅ Live — reads `boroScores` from localStorage, calculates predicted wins/draws/losses, determines profile.

**Thresholds:**
- 🌧️ **Pessimist** — <50 pts predicted
- 🔬 **Realist** — 50–74 pts predicted
- ☀️ **Optimist** — 75+ pts predicted

**Future improvement:** Once actual results are in, compare predicted vs actual to refine the archetype (e.g. "Realist who correctly called 7 Boro wins").

### Panel 4 — Season Achievement
**What:** The player's rarest correct prediction — the scoreline they got right that the fewest other players also got right.

**Current state:** Locked state shown (no blur). Preview example shown in greyed-out card.

**To make live:**
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
