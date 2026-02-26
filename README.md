# Pomodoro Timer

A web-based Pomodoro Timer application built with Elixir, Phoenix, and LiveView. This application helps you implement the Pomodoro Technique - a time management method that uses a timer to break work into intervals, traditionally 25 minutes in length, separated by short breaks.
This implementation will keep running, event after you close the tab, without any need for user accounts.

## Live Demo

Try out the Pomodoro Timer in action: [**Live Demo**](https://pomofocus.uk/)

[![Pomodoro Timer Screenshot](/priv/static/images/pomodoro_screenshot.png)](https://pomofocus.uk/)

Backup link: https://pomofocus.duckdns.org

## About the Pomodoro Technique

The Pomodoro Technique is a time management method developed by Francesco Cirillo in the late 1980s. The technique uses a timer to break down work into intervals, traditionally 25 minutes in length, separated by short breaks. Each interval is known as a "pomodoro", from the Italian word for tomato, after the tomato-shaped kitchen timer Cirillo used as a university student.

The technique follows these steps:

1. Decide on the task to be done
2. Set the timer for 25 minutes (one pomodoro)
3. Work on the task until the timer rings
4. Take a short 5-minute break
5. After four pomodoros, take a longer break (15-30 minutes)

## Features

- 25-minute focus timer
- 5-minute break timer
- Streak counter (consecutive days with at least one completed focus session)
- Contribution-style heatmap (52 weeks × 7 days) for session history
- Session stats stored in the database; optional Google/GitHub sign-in for cross-device sync (see **Settings**)
- Simple, clean user interface
- Real-time timer updates
- Automatic session tracking with browser cookies
- Mobile-friendly responsive design

## Using the Application

1. **Access the Application**: Open your web browser and navigate to the application URL
2. **Start a Focus Session**: Click the "Focus" button to start a 25-minute focus session
3. **Take a Break**: When the focus session ends, click the "Break" button to start a 5-minute break
4. **Repeat**: Continue alternating between focus and break sessions

The application automatically saves your session state, so you can close your tab and return to where you left off.

Session stats (streak and heatmap) are stored in the database. Optionally, sign in with Google or GitHub in **Settings** to link your account for cross-device sync.

## Development Setup

### Prerequisites

- Elixir 1.14 or later
- Erlang/OTP 25 or later
- SQLite3

### Installation Steps

1. Clone the repository:

   ```bash
   git clone https://github.com/yourusername/pomodoro.git
   cd pomodoro
   ```

2. Install dependencies:

   ```bash
   mix setup
   ```

3. Start the Phoenix server:

   ```bash
   mix phx.server
   ```

4. Visit [`localhost:4000`](http://localhost:4000) from your browser.

### Running Tests

```bash
mix test
```

### Mix tasks

- **`mix pomodoro.analytics.query`** — Print usage summary. Use `--sessions 7` or `--users 7` for per-day stats over the last 7 days.
- **`mix pomodoro.session_stats.seed`** — Generate sample session data (JSON) for the last 90 days (use `--days N` to change). Copy the output and paste into the browser console as `localStorage.setItem('pomodoro_session_stats', '<paste>');` then reload to test the heatmap and streak UI.

### Session stats

Session stats (date and count per day) are stored in the `pomodoro_sessions` table. The client may cache them in localStorage under `pomodoro_session_stats` for quick display. Sign in with Google or GitHub in Settings to link your account for optional cross-device sync.

## Deployment / Environment variables

For production (e.g. Docker or a release), set these in the environment. **Never commit real values** (this is a public repo). Use `.env` (gitignored) or your platform’s secret store.

| Variable | Required | Description |
|----------|----------|-------------|
| `SECRET_KEY_BASE` | Yes | Used to sign cookies. Generate with `mix phx.gen.secret`. |
| `GOOGLE_CLIENT_ID` | No | Google OAuth client ID (for sign-in). |
| `GOOGLE_CLIENT_SECRET` | No | Google OAuth client secret. |
| `GITHUB_CLIENT_ID` | No | GitHub OAuth client ID (for sign-in). |
| `GITHUB_CLIENT_SECRET` | No | GitHub OAuth client secret. |
| `DATABASE_PATH` | Yes | Path to the SQLite database file (e.g. `/app/data/pomodoro.db`). |
| `PHX_SERVER` | No | Set to `true` when running the release server. |
| `PORT` | No | HTTP port (default `4000`). |
| `PHX_HOST` | No | Host for URL generation (default `example.com`). |
| `POOL_SIZE` | No | Ecto pool size (default `5`). |

Copy `.env.example` to `.env` and fill in values for local or production use.
