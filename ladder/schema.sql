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

-- Insert all 46 fixtures — kept in sync with the fixtures array in
-- predict/index.html. If that array changes, update both.
INSERT INTO public.fixtures (fixture_index, home_team, away_team, match_date, is_boro_home) VALUES
(0,  'Middlesbrough',            'Lincoln City',              '2026-08-15', TRUE),
(1,  'Blackburn Rovers',         'Middlesbrough',              '2026-08-22', FALSE),
(2,  'Middlesbrough',            'West Brom',                  '2026-08-29', TRUE),
(3,  'Burnley',                  'Middlesbrough',              '2026-09-02', FALSE),
(4,  'QPR',                      'Middlesbrough',              '2026-09-05', FALSE),
(5,  'Middlesbrough',            'Millwall',                   '2026-09-08', TRUE),
(6,  'Middlesbrough',            'Norwich City',               '2026-09-12', TRUE),
(7,  'Birmingham City',          'Middlesbrough',              '2026-09-19', FALSE),
(8,  'Middlesbrough',            'Wolverhampton Wanderers',    '2026-10-10', TRUE),
(9,  'Stoke City',               'Middlesbrough',              '2026-10-13', FALSE),
(10, 'Middlesbrough',            'Cardiff City',               '2026-10-17', TRUE),
(11, 'Bolton Wanderers',         'Middlesbrough',              '2026-10-24', FALSE),
(12, 'Middlesbrough',            'Charlton Athletic',          '2026-10-31', TRUE),
(13, 'Wrexham',                  'Middlesbrough',              '2026-11-04', FALSE),
(14, 'Watford',                  'Middlesbrough',              '2026-11-07', FALSE),
(15, 'Middlesbrough',            'Bristol City',               '2026-11-21', TRUE),
(16, 'Middlesbrough',            'Swansea City',               '2026-11-24', TRUE),
(17, 'Southampton',              'Middlesbrough',              '2026-11-28', FALSE),
(18, 'Middlesbrough',            'Derby County',               '2026-12-05', TRUE),
(19, 'West Ham United',          'Middlesbrough',              '2026-12-08', FALSE),
(20, 'Preston North End',        'Middlesbrough',              '2026-12-12', FALSE),
(21, 'Middlesbrough',            'Portsmouth',                 '2026-12-19', TRUE),
(22, 'Sheffield United',         'Middlesbrough',              '2026-12-26', FALSE),
(23, 'Middlesbrough',            'Bolton Wanderers',           '2026-12-29', TRUE),
(24, 'Middlesbrough',            'Preston North End',          '2027-01-01', TRUE),
(25, 'Cardiff City',             'Middlesbrough',              '2027-01-16', FALSE),
(26, 'Charlton Athletic',        'Middlesbrough',              '2027-01-23', FALSE),
(27, 'Middlesbrough',            'Wrexham',                    '2027-01-27', TRUE),
(28, 'Middlesbrough',            'Watford',                    '2027-01-30', TRUE),
(29, 'Bristol City',             'Middlesbrough',              '2027-02-06', FALSE),
(30, 'Norwich City',             'Middlesbrough',              '2027-02-13', FALSE),
(31, 'Middlesbrough',            'Stoke City',                 '2027-02-17', TRUE),
(32, 'Middlesbrough',            'Birmingham City',            '2027-02-20', TRUE),
(33, 'Wolverhampton Wanderers',  'Middlesbrough',              '2027-02-27', FALSE),
(34, 'Middlesbrough',            'Blackburn Rovers',           '2027-03-02', TRUE),
(35, 'Lincoln City',             'Middlesbrough',              '2027-03-06', FALSE),
(36, 'Middlesbrough',            'Southampton',                '2027-03-13', TRUE),
(37, 'Derby County',             'Middlesbrough',              '2027-03-16', FALSE),
(38, 'Middlesbrough',            'Sheffield United',           '2027-03-20', TRUE),
(39, 'Portsmouth',               'Middlesbrough',              '2027-04-03', FALSE),
(40, 'Millwall',                 'Middlesbrough',              '2027-04-06', FALSE),
(41, 'Middlesbrough',            'QPR',                        '2027-04-10', TRUE),
(42, 'West Brom',                'Middlesbrough',              '2027-04-17', FALSE),
(43, 'Middlesbrough',            'Burnley',                    '2027-04-20', TRUE),
(44, 'Middlesbrough',            'West Ham United',            '2027-04-24', TRUE),
(45, 'Swansea City',             'Middlesbrough',              '2027-05-01', FALSE);


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

-- Predictions: users can read all (for ladder), only write their own,
-- and only before the season deadline — enforced here so it can't be
-- bypassed by the client, regardless of any UI-level lock messaging.
CREATE POLICY "predictions_select_all" ON public.predictions
  FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "predictions_insert_own" ON public.predictions
  FOR INSERT WITH CHECK (
    auth.uid() = player_id
    AND now() < '2026-08-15T00:00:00Z'::timestamptz
  );
CREATE POLICY "predictions_update_own" ON public.predictions
  FOR UPDATE USING (auth.uid() = player_id)
  WITH CHECK (
    auth.uid() = player_id
    AND now() < '2026-08-15T00:00:00Z'::timestamptz
  );
CREATE POLICY "predictions_delete_own" ON public.predictions
  FOR DELETE USING (
    auth.uid() = player_id
    AND now() < '2026-08-15T00:00:00Z'::timestamptz
  );


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
