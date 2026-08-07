// sync-odds — Supabase Edge Function
//
// Runs on a daily cron schedule (set up in the Supabase dashboard). Finds the
// next unplayed Boro fixture, looks it up on The Odds API, pulls correct-score
// odds for a single fixed UK bookmaker, and upserts them into public.odds.
//
// The Odds API key is never shipped to the browser — it lives only as this
// function's ODDS_API_KEY secret. This function uses the service-role key
// (auto-injected as SUPABASE_SERVICE_ROLE_KEY) so it can write to `odds`,
// which regular users/clients cannot (see ladder/schema.sql — odds_select
// is SELECT-only for authenticated users, no insert/update policy exists).
//
// See analyst/SPEC.md § "Points Projection (Bookies)" for the full design.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL          = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const ODDS_API_KEY          = Deno.env.get('ODDS_API_KEY')!;

const SPORT_KEY        = 'soccer_efl_champ';
const PREFERRED_BOOKIE  = 'bet365'; // single fixed bookmaker per SPEC.md decision

const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE);

// Team names differ between our `fixtures` table and The Odds API's event
// data (e.g. "West Brom" vs "West Bromwich Albion"). Normalise both sides
// before comparing so a reasonable substring match still lines up.
function normaliseTeam(name: string): string {
  return name
    .toLowerCase()
    .replace(/\bfc\b/g, '')
    .replace(/[^a-z]/g, '');
}

function teamsMatch(ourName: string, apiName: string): boolean {
  const a = normaliseTeam(ourName);
  const b = normaliseTeam(apiName);
  return a === b || a.includes(b) || b.includes(a);
}

async function getNextFixture() {
  const [{ data: fixtures }, { data: results }] = await Promise.all([
    sb.from('fixtures').select('fixture_index, home_team, away_team').order('fixture_index'),
    sb.from('results').select('fixture_index'),
  ]);
  if (!fixtures || fixtures.length === 0) return null;
  const played = new Set((results ?? []).map((r) => r.fixture_index));
  return fixtures.find((f) => !played.has(f.fixture_index)) ?? null;
}

async function findEvent(homeTeam: string, awayTeam: string) {
  const url = `https://api.the-odds-api.com/v4/sports/${SPORT_KEY}/events?apiKey=${ODDS_API_KEY}`;
  const res = await fetch(url);
  if (!res.ok) {
    // DEBUG: surface the actual API error instead of silently returning
    // an empty list, so a bad key / wrong sport key / rate limit is visible.
    const body = await res.text();
    return {
      match: null,
      events: [] as { home_team: string; away_team: string }[],
      fetchError: { status: res.status, body },
    };
  }
  const events = await res.json();
  const match = events.find(
    (e: { home_team: string; away_team: string }) =>
      teamsMatch(homeTeam, e.home_team) && teamsMatch(awayTeam, e.away_team)
  );
  return { match, events, fetchError: null };
}

interface OddsOutcome { name: string; price: number }
interface OddsMarket { key: string; outcomes: OddsOutcome[] }
interface OddsBookmaker { key: string; markets: OddsMarket[] }

async function fetchCorrectScoreOdds(
  eventId: string
): Promise<{ bookmakers: OddsBookmaker[] | null; fetchError: { status: number; body: string } | null }> {
  const url =
    `https://api.the-odds-api.com/v4/sports/${SPORT_KEY}/events/${eventId}/odds` +
    `?apiKey=${ODDS_API_KEY}&markets=correct_score&regions=uk&oddsFormat=decimal`;
  const res = await fetch(url);
  if (!res.ok) {
    // DEBUG: surface the actual API error instead of a bare null, so we can
    // tell "market not covered" apart from a genuine request failure.
    const body = await res.text();
    return { bookmakers: null, fetchError: { status: res.status, body } };
  }
  const data = await res.json();
  return { bookmakers: data.bookmakers ?? null, fetchError: null };
}

// Outcome names for the correct_score market are plain "H-A" scorelines,
// e.g. "2-1". Confirm this against a live response and adjust if the API
// actually returns a different format (this was not directly testable
// without a key at the time this function was written).
function parseScoreline(name: string): { home: number; away: number } | null {
  const m = name.match(/^(\d+)[-:](\d+)$/);
  if (!m) return null;
  return { home: Number(m[1]), away: Number(m[2]) };
}

Deno.serve(async () => {
  const nextFixture = await getNextFixture();
  if (!nextFixture) {
    return new Response(JSON.stringify({ skipped: 'season complete, no fixture to fetch odds for' }), { status: 200 });
  }

  const { match, events, fetchError } = await findEvent(nextFixture.home_team, nextFixture.away_team);
  if (!match) {
    // DEBUG: report what The Odds API actually has on offer (or why the
    // request itself failed) so we can see whether this is a team-name
    // mismatch, an empty events list, or a request error (bad key, wrong
    // sport key, rate limit, etc).
    return new Response(
      JSON.stringify({
        skipped: `no matching event found for fixture ${nextFixture.fixture_index}`,
        lookingFor: { home: nextFixture.home_team, away: nextFixture.away_team },
        availableEvents: events.map((e) => `${e.home_team} vs ${e.away_team}`),
        fetchError,
      }),
      { status: 200 }
    );
  }
  const eventId = match.id;

  const { bookmakers, fetchError: oddsFetchError } = await fetchCorrectScoreOdds(eventId);
  if (!bookmakers || bookmakers.length === 0) {
    return new Response(
      JSON.stringify({ skipped: 'correct_score market not available for this fixture yet', fetchError: oddsFetchError }),
      { status: 200 }
    );
  }

  // Prefer the fixed bookmaker; fall back to whichever UK book actually has
  // this market, since correct-score coverage is limited per The Odds API docs.
  const book = bookmakers.find((b) => b.key === PREFERRED_BOOKIE) ?? bookmakers[0];
  const market = book.markets.find((m) => m.key === 'correct_score');
  if (!market) {
    return new Response(JSON.stringify({ skipped: 'no correct_score market in response' }), { status: 200 });
  }

  const rows = market.outcomes
    .map((o) => {
      const score = parseScoreline(o.name);
      if (!score) return null;
      return {
        fixture_index: nextFixture.fixture_index,
        home_goals: score.home,
        away_goals: score.away,
        decimal_odds: o.price,
        bookmaker: book.key,
      };
    })
    .filter((r): r is NonNullable<typeof r> => r !== null);

  if (rows.length === 0) {
    return new Response(JSON.stringify({ skipped: 'no parseable scoreline outcomes' }), { status: 200 });
  }

  const { error } = await sb
    .from('odds')
    .upsert(rows, { onConflict: 'fixture_index,home_goals,away_goals' });

  if (error) {
    console.error('upsert failed', error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }

  return new Response(
    JSON.stringify({ fixture_index: nextFixture.fixture_index, bookmaker: book.key, rows: rows.length }),
    { status: 200 }
  );
});
