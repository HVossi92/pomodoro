/**
 * Session stats localStorage helpers.
 * Key: pomodoro_session_stats
 * Shape: { sessions: [{ date: "YYYY-MM-DD", count: n }, ...], github_gist_id? }
 * Token is stored on the server (BFF); only gist_id is kept here for UI state.
 */

const SESSION_STATS_KEY = "pomodoro_session_stats";

const defaultData = () => ({
  sessions: [],
  github_gist_id: null
});

export function getSessionStatsData() {
  try {
    const raw = localStorage.getItem(SESSION_STATS_KEY);
    if (!raw) return defaultData();
    const data = JSON.parse(raw);
    return {
      sessions: Array.isArray(data.sessions) ? data.sessions : [],
      github_gist_id: data.github_gist_id ?? null
    };
  } catch (_e) {
    return defaultData();
  }
}

export function saveSessionStatsData(data) {
  const payload = {
    sessions: data.sessions ?? [],
    github_gist_id: data.github_gist_id ?? null
  };
  localStorage.setItem(SESSION_STATS_KEY, JSON.stringify(payload));
}

/**
 * Returns local date as YYYY-MM-DD (browser timezone).
 */
export function localDateString(date = new Date()) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

/**
 * Adds one completed session for the given date (YYYY-MM-DD).
 * Updates localStorage and returns the updated full data.
 */
export function addSession(date) {
  const data = getSessionStatsData();
  const sessions = [...(data.sessions || [])];
  const idx = sessions.findIndex((s) => s.date === date);
  if (idx >= 0) {
    sessions[idx] = { ...sessions[idx], count: (sessions[idx].count || 0) + 1 };
  } else {
    sessions.push({ date, count: 1 });
  }
  sessions.sort((a, b) => (b.date > a.date ? 1 : -1));
  const updated = { ...data, sessions };
  saveSessionStatsData(updated);
  return updated;
}

export { SESSION_STATS_KEY };
