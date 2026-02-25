/**
 * GitHub Gist API helpers (client-side only).
 * Requires token with gist scope.
 */

const GIST_API = "https://api.github.com/gists";
const GIST_FILE_NAME = "pomodoro.json";

export async function createGist(token, data) {
  const res = await fetch(GIST_API, {
    method: "POST",
    headers: {
      Authorization: `token ${token}`,
      Accept: "application/vnd.github.v3+json",
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      description: "Pomodoro session stats",
      public: false,
      files: { [GIST_FILE_NAME]: { content: JSON.stringify(data) } }
    })
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.message || `Gist create failed: ${res.status}`);
  }
  const json = await res.json();
  if (!json.id || String(json.id).trim() === "") {
    throw new Error("missing gist id");
  }
  return json.id;
}

export async function fetchGist(token, gistId) {
  const res = await fetch(`${GIST_API}/${gistId}`, {
    headers: {
      Authorization: `token ${token}`,
      Accept: "application/vnd.github.v3+json"
    }
  });
  if (!res.ok) throw new Error(`Gist fetch failed: ${res.status}`);
  const json = await res.json();
  const file = json.files && json.files[GIST_FILE_NAME];
  if (!file || !file.content) return null;
  try {
    return JSON.parse(file.content);
  } catch (_e) {
    return null;
  }
}

export async function updateGist(token, gistId, data) {
  const res = await fetch(`${GIST_API}/${gistId}`, {
    method: "PATCH",
    headers: {
      Authorization: `token ${token}`,
      Accept: "application/vnd.github.v3+json",
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      files: { [GIST_FILE_NAME]: { content: JSON.stringify(data) } }
    })
  });
  if (!res.ok) throw new Error(`Gist update failed: ${res.status}`);
}
