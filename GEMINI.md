# Gemini Agent Project Context: Personal Color Diagnosis App

## Project Overview

This is a monorepo for a "Personal Color Diagnosis" application. The project's main goal is to provide an AI-powered tool that analyzes a user's photo to determine their personal color, specifically whether they are "Yellow Base" or "Blue Base". It also includes features for AI-powered makeup simulation and fashion coordination advice based on the user's personal color.

The project consists of three main components:
1.  **Mobile App**: A Flutter-based application targeted at elementary school students for iOS and Android.
2.  **Backend API**: A Python server using FastAPI that leverages Google's Vertex AI (with the Gemini model) to perform the actual image analysis and color diagnosis.
3.  **Teaser Website**: A static promotional website built with Next.js and hosted on Firebase.

The architecture emphasizes safety and privacy, with a commitment to deleting user images immediately after diagnosis.

### Technology Stack

-   **Mobile App**: Flutter (v3.32+) for iOS and Android.
-   **Web Frontend**: Next.js (v15, App Router), TypeScript, Tailwind CSS.
-   **Backend Server**: Python (v3.11+), FastAPI, Vertex AI Gemini.
-   **Hosting**:
    -   Mobile: Apple App Store & Google Play Store.
    -   Web: Firebase Hosting.
    -   Server: (Assumed to be a container-based service like Cloud Run, given the Docker setup).

## Building and Running

### 1. Mobile App (Flutter)

Navigate to the client directory to run the app.

```bash
cd client/personal_color_app/

# First-time setup (installs dependencies)
make setup

# Run on iOS Simulator
make ios-debug

# Run on Android Emulator
make android-debug

# See all available commands
make help
```

### 2. Web Frontend (Next.js)

Navigate to the web directory to run the teaser site.

```bash
cd web/

# Install dependencies
npm install

# Start the development server
npm run dev
```

### 3. Backend Server (Python/FastAPI)

The server runs via Docker. Ensure you have Docker installed and running.

```bash
cd server/

# Create a .env file from the example
cp .env.example .env

# TODO: Populate .env with necessary credentials for Vertex AI.

# Build and run the services using Docker Compose
docker-compose up --build
```
The API will be available at `http://localhost:8000`, with interactive documentation at `http://localhost:8000/docs`.

## Development Conventions

-   **Specification First**: All development should follow the specifications laid out in the `/specifications` directory.
-   **Architecture**: The project follows Clean Architecture and Domain-Driven Design (DDD) principles.
-   **Testing**: Test-Driven Development (TDD) is the standard practice. Key testing commands are `make test` for the mobile app and `pytest` for the server.
-   **API**: The backend exposes a RESTful API. An OpenAPI specification snapshot can be found in `docs/openapi_example.json`.
-   **Environment Configuration**: The server is configured via a `.env` file. See `server/.env.example` for available options, such as feature flags (`ENHANCED_DIAGNOSIS_ENABLED`) and image size limits.
