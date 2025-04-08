# Pomodoro Timer

A web-based Pomodoro Timer application built with Elixir, Phoenix, and LiveView. This application helps you implement the Pomodoro Technique - a time management method that uses a timer to break work into intervals, traditionally 25 minutes in length, separated by short breaks.

![Pomodoro Timer](/priv/static/images/pomodoro_screenshot.png)

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
3. **Pause if Needed**: Click the button again to pause the timer
4. **Take a Break**: When the focus session ends, click the "Break" button to start a 5-minute break
5. **Repeat**: Continue alternating between focus and break sessions

The application automatically saves your session state, so you can close your browser and return later to continue where you left off.

## Development Setup

### Prerequisites

- Elixir 1.14 or later
- Erlang/OTP 25 or later
- Node.js 16 or later
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

## Todos:

### 1. Setup Project

- [x] Create a new Phoenix project with LiveView support
- [x] Configure Tailwind CSS
- [x] Set up basic project structure
- [x] Create the main layout

### 2. Design Data Model

- [x] Define data structures to track:
  - [x] Current mode (focus, break, etc.)
  - [x] Timer duration (25 minutes for focus, 5 minutes for break)
  - [x] Current timer value
  - [x] Timer status (running, paused, stopped)

### 3. Create Timer Core Logic

- [x] Design a Timer context to handle the timer functionality
- [x] Implement functions to:
  - [x] Start the timer
  - [x] Pause the timer
  - [ ] Reset the timer
  - [ ] Handle timer completion
  - [ ] Switch between Focus and Break modes

### 4. Implement LiveView Component

- [x] Create a LiveView module for the timer
- [x] Set up the initial state with default values (25:00)
- [x] Implement mount and handle_event callbacks
- [x] Create a timer update mechanism (using Process.send_after for second-by-second updates)
- [x] Define event handlers for user actions (start, pause, reset)

### 5. Design UI with Tailwind CSS

- [x] Create a clean, centered layout
- [x] Design the timer display with large, readable numbers
- [x] Create buttons for controlling the timer (Focus, Break, Reset)
- [x] Add visual feedback for current timer state
- [x] Implement responsive design

### 6. Add Interactivity

- [x] Connect UI buttons to LiveView events
- [x] Implement real-time updates of the timer display
- [ ] Add visual and audio indicators for timer completion
- [ ] Implement smooth transitions between states

### 7. Advanced Features (for future iterations)

- [ ] Statistics and reports

### 8. Testing

- [ ] Write unit tests for the timer logic
- [ ] Create component tests for the LiveView
- [ ] Perform end-to-end testingPomodoro Timer Web App - Step by Step Plan

### 9. Deployment

- [ ] Prepare the application for production
- [ ] Deploy to a hosting service

### 10. MISC

- [x] Add data privacy page
- [] Check functionality in incognito mode
