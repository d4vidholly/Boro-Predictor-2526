-- ============================================================
-- BORO PREDICTOR 26/27 — SUPABASE SCHEMA
-- Run this entire file in your Supabase SQL Editor.
-- ============================================================


-- ── WAITLIST (landing page email capture) ──────────────────
CREATE TABLE public.waitlist (
  id         SERIAL PRIMARY KEY,
  email      TEXT UNIQUE NOT NULL,
  signed_up_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── PLAYERS (one row per registered user) ─────────────────
-- Linked 1-to-1 with Supabase auth.users via magic link.
CREATE TABLE public.players (
  id         UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email      TEXT NOT NULL,
  name       TEXT NOT NULL,
  team_name  TEXT,                      -- optional custom team name
  is_premium BOOLEAN DEFAULT FALSE,
  joined_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── FIXTURES (static — all 46 Boro matches) ───────────────
CREATE TABLE public.fixtures (
  id            SERIAL PRIMARY KEY,
  fixture_index INTEGER NOT NULL UNIQUE,  -- 0-based, matches JS array index
  home_team     TEXT NOT NULL,
  away_team     TEXT NOT NULL,
  match_date    DATE,                     -- update when full schedule released
  is_boro_home  BOOLEAN NOT NULL
);

-- Insert all 46 fixtures (dates TBC for fixtures 1-45)
INSERT INTO public.fixtures (fixture_index, home_team, away_team, match_date, is_boro_home) VALUES
(0,  'Middlesbrough', 'Swansea City',       '2025-08-09', TRUE),
(1,  'Millwall', 'Middlesbrough',           NULL, FALSE),
(2,  'Norwich City', 'Middlesbrough',       NULL, FALSE),
(3,  'Middlesbrough', 'Sheffield United',   NULL, TRUE),
(4,  'Preston North End', 'Middlesbrough',  NULL, FALSE),
(5,  'Middlesbrough', 'West Brom',          NULL, TRUE),
(6,  'Southampton', 'Middlesbrough',        NULL, FALSE),
(7,  'Middlesbrough', 'Stoke City',         NULL, TRUE),
(8,  'Portsmouth', 'Middlesbrough',         NULL, FALSE),
(9,  'Middlesbrough', 'Ipswich Town',       NULL, TRUE),
(10, 'Sheffield Wednesday', 'Middlesbrough',NULL, FALSE),
(11, 'Middlesbrough', 'Wrexham',            NULL, TRUE),
(12, 'Watford', 'Middlesbrough',            NULL, FALSE),
(13, 'Leicester City', 'Middlesbrough',     NULL, FALSE),
(14, 'Middlesbrough', 'Birmingham City',    NULL, TRUE),
(15, 'Oxford United', 'Middlesbrough',      NULL, FALSE),
(16, 'Middlesbrough', 'Coventry City',      NULL, TRUE),
(17, 'Middlesbrough', 'Derby County',       NULL, TRUE),
(18, 'Hull City', 'Middlesbrough',          NULL, FALSE),
(19, 'Charlton Athletic', 'Middlesbrough',  NULL, FALSE),
(20, 'Middlesbrough', 'QPR',                NULL, TRUE),
(21, 'Bristol City', 'Middlesbrough',       NULL, FALSE),
(22, 'Middlesbrough', 'Blackburn Rovers',   NULL, TRUE),
(23, 'Middlesbrough', 'Hull City',          NULL, TRUE),
(24, 'Derby County', 'Middlesbrough',       NULL, FALSE),
(25, 'Middlesbrough', 'Southampton',        NULL, TRUE),
(26, 'West Brom', 'Middlesbrough',          NULL, FALSE),
(27, 'Stoke City', 'Middlesbrough',         NULL, FALSE),
(28, 'Middlesbrough', 'Preston North End',  NULL, TRUE),
(29, 'Middlesbrough', 'Norwich City',       NULL, TRUE),
(30, 'Sheffield United', 'Middlesbrough',   NULL, FALSE),
(31, 'Coventry City', 'Middlesbrough',      NULL, FALSE),
(32, 'Middlesbrough', 'Oxford United',      NULL, TRUE),
(33, 'Middlesbrough', 'Leicester City',     NULL, TRUE),
(34, 'Birmingham City', 'Middlesbrough',    NULL, FALSE),
(35, 'QPR', 'Middlesbrough',               NULL, FALSE),
(36, 'Middlesbrough', 'Charlton Athletic',  NULL, TRUE),
(37, 'Middlesbrough', 'Bristol City',       NULL, TRUE),
(38, 'Blackburn Rovers', 'Middlesbrough',   NULL, FALSE),
(39, 'Middlesbrough', 'Millwall',           NULL, TRUE),
(40, 'Swansea City', 'Middlesbrough',       NULL, FALSE),
(41, 'Middlesbrough', 'Portsmouth',         NULL, TRUE),
(42, 'Ipswich Town', 'Middlesbrough',       NULL, FALSE),
(43, 'Middlesbrough', 'Sheffield Wednesday',NULL, TRUE),
(44, 'Middlesbrough', 'Watford',            NULL, TRUE),
(45, 'Wrexham', 'Middlesbrough',            NULL, FALSE);


-- ── PREDICTIONS (one row per player per fixture) ──────────
CREATE TABLE public.predictions (
  id            SERIAL PRIMARY KEY,
  player_id     UUID NOT NULL REFERENCES public.players(id) ON DELETE CASCADE,
  fixture_index INTEGER NOT NULL REFERENCES public.fixtures(fixture_index),
  home_goals    INTEGER NOT NULL DEFAULT 0 CHECK (home_goals BETWEEN 0 AND 9),
  away_goals    INTEGER NOT NULL DEFAULT 0 CHECK (away_goals BETWEEN 0 AND 9),
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(player_id, fixture_index)
);

-- ── RESULTS (filled in after each match) ──────────────────
CREATE TABLE public.results (
  id            SERIAL PRIMARY KEY,
  fixture_index INTEGER NOT NULL UNIQUE REFERENCES public.fixtures(fixture_index),
  home_goals    INTEGER NOT NULL,
  away_goals    INTEGER NOT NULL,
  played_at     TIMESTAMPTZ DEFAULT NOW()
);

-- ── SETTINGS (global app config) ──────────────────────────
CREATE TABLE public.settings (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

-- predictions_locked: set to 'true' to lock all predictions
INSERT INTO public.settings (key, value) VALUES ('predictions_locked', 'false');


-- ── LADDER VIEW ───────────────────────────────────────────
-- Scoring per fixture:
--   Exact scoreline (home AND away correct) → 4 points
--   Otherwise: correct home goals → 1pt
--              correct away goals → 1pt
--              correct result (W/D/L) → 1pt
CREATE OR REPLACE VIEW public.ladder AS
SELECT
  p.id                                          AS player_id,
  p.name,
  p.team_name,
  COUNT(r.fixture_index)                        AS played,
  COALESCE(SUM(
    CASE
      WHEN pred.home_goals = r.home_goals
       AND pred.away_goals = r.away_goals
      THEN 4
      ELSE
        CASE WHEN pred.home_goals = r.home_goals THEN 1 ELSE 0 END +
        CASE WHEN pred.away_goals = r.away_goals THEN 1 ELSE 0 END +
        CASE
          WHEN (pred.home_goals > pred.away_goals AND r.home_goals > r.away_goals)
            OR (pred.home_goals < pred.away_goals AND r.home_goals < r.away_goals)
            OR (pred.home_goals = pred.away_goals AND r.home_goals = r.away_goals)
          THEN 1 ELSE 0
        END
    END
  ), 0)                                         AS points,
  COALESCE(SUM(
    CASE WHEN pred.home_goals = r.home_goals
          AND pred.away_goals = r.away_goals
         THEN 1 ELSE 0 END
  ), 0)                                         AS correct_scores,
  COALESCE(SUM(
    CASE
      WHEN (pred.home_goals > pred.away_goals AND r.home_goals > r.away_goals)
        OR (pred.home_goals < pred.away_goals AND r.home_goals < r.away_goals)
        OR (pred.home_goals = pred.away_goals AND r.home_goals = r.away_goals)
      THEN 1 ELSE 0
    END
  ), 0)                                         AS correct_results
FROM public.players p
LEFT JOIN public.predictions pred ON pred.player_id = p.id
LEFT JOIN public.results r        ON r.fixture_index = pred.fixture_index
GROUP BY p.id, p.name, p.team_name
ORDER BY points DESC NULLS LAST, correct_scores DESC NULLS LAST, correct_results DESC NULLS LAST;


-- ── ROW LEVEL SECURITY ────────────────────────────────────
ALTER TABLE public.waitlist    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.players     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.results     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fixtures    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings    ENABLE ROW LEVEL SECURITY;

-- Waitlist: anyone can insert their email (anon allowed)
CREATE POLICY "waitlist_insert" ON public.waitlist
  FOR INSERT WITH CHECK (TRUE);

-- Players: any authenticated user can read all players (required for the
-- ladder view's join across players — same trust model as predictions_select_all
-- below, since predictions are already fully readable across players).
-- Only the owning player can update their own row.
CREATE POLICY "players_select_all" ON public.players
  FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "players_update_own" ON public.players
  FOR UPDATE USING (auth.uid() = id);

-- Fixtures: all authenticated users can read
CREATE POLICY "fixtures_select" ON public.fixtures
  FOR SELECT USING (auth.role() = 'authenticated');

-- Results: all authenticated users can read
CREATE POLICY "results_select" ON public.results
  FOR SELECT USING (auth.role() = 'authenticated');

-- Settings: all authenticated users can read
CREATE POLICY "settings_select" ON public.settings
  FOR SELECT USING (auth.role() = 'authenticated');

-- Predictions: users can read all (for ladder), only write their own
CREATE POLICY "predictions_select_all" ON public.predictions
  FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "predictions_insert_own" ON public.predictions
  FOR INSERT WITH CHECK (auth.uid() = player_id);
CREATE POLICY "predictions_update_own" ON public.predictions
  FOR UPDATE USING (auth.uid() = player_id);


-- ── TRIGGER: auto-create player row on first login ────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.players (id, email, name)
  VALUES (
    NEW.id,
    NEW.email,
    SPLIT_PART(NEW.email, '@', 1)  -- default name from email, user can change in settings
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
