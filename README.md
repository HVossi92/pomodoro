# Pomodoro Timer

A web-based Pomodoro Timer application built with Elixir, Phoenix, and LiveView. This application helps you implement the Pomodoro Technique - a time management method that uses a timer to break work into intervals, traditionally 25 minutes in length, separated by short breaks.
This implementation will keep running, event after you close the tab, without any need for user accounts.

## Live Demo

Try out the Pomodoro Timer in action: [**Live Demo**](https://pomofocus.duckdns.org)

[![Pomodoro Timer Screenshot](/priv/static/images/pomodoro_screenshot.png)](https://pomofocus.duckdns.org)

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
