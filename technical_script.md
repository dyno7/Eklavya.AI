# Eklavya.AI Architecture Review

## Overview
What we are demonstrating today is Eklavya.AI operating across two distinct platforms: our React-based web application and our Flutter-based mobile application.

While the frontends look and feel distinct, the underlying architecture adheres strictly to a "Thin Client" model. Neither the web app nor the mobile app handles core business logic, data mutation rules, or AI interactions natively. Instead, they act exclusively as presentation layers that synchronize with a centralized, shared backend.

Below is a technical breakdown of this architecture.

## 1. The Presentation Layer (Web & Mobile)
We maintain two independent codebases for the frontends:
*   **Web (React):** Optimized for wide-viewport learning environments and desktop utility.
*   **Mobile (Flutter):** Provides native hardware acceleration, utilizing cross-platform libraries like `flutter_animate` and `go_router` for deep linking and state restoration. For state management, the Flutter app utilizes `Riverpod`.

*Key Principle*: The frontends only manage local UX state (navigation, animations, and form validation) and consume JSON responses provided by the backend APIs.

## 2. The API and Application Layer (FastAPI)
The core of Eklavya.AI is a Python 3.12 application built on the FastAPI framework.

*   **Asynchronous I/O:** FastAPI, built on standard Python async typings, handles high concurrent throughput inherently required by our real-time gamification and chat engines.
*   **Clean Architecture:** The application directory logic separates presentation (API routers), domain (Pydantic models and SQLAlchemy schemas), and infrastructure (PostgreSQL repositories). This decoupling allows us to scale individual domains independently without side effects.
*   **Dependency Injection:** We utilize FastAPI's native dependency injection to securely resolve database sessions and authenticated user context on a per-request basis.

## 3. The Data Layer (Supabase & PostgreSQL)
Rather than abstracting our database via typical Backend-as-a-Service visual builders, we rely on Supabase as a fully managed PostgreSQL instance.

*   **ORM and Drivers:** Our Python backend communicates directly with the PostgreSQL database using `SQLAlchemy 2.0` combined with the `asyncpg` driver for non-blocking database queries.
*   **Database Migrations:** Schema evolution (like adding our gamification tables for goals, milestones, and tasks) is explicitly version-controlled and applied utilizing `Alembic`.
*   **Realtime Capabilities:** When state is fundamentally mutated via the backend, Supabase's Realtime Postgres replication enables real-time synchronization between the Web and Mobile app without constant REST polling.

## 4. Unified Authentication (OAuth & JWT)
Authentication state is managed seamlessly across platforms avoiding duplicate login infrastructure.

*   **Token Generation:** Both the React and Flutter apps authenticate through Supabase Auth, which issues a short-lived JSON Web Token (JWT) locally to the device.
*   **Token Verification:** When an API request is made, the frontend passes this JWT via a Bearer token in the request header. The FastAPI backend validates this token mathematically using the Supabase JWT secret. This allows the backend API to extract user context without requiring a database lookup per request.

## 5. The AI Orchestration Layer (Gemini)
The fundamental differentiator in our stack is that the AI prompt engineering and generative logic is sandboxed securely behind the API wall.

*   **Model Integration:** The backend integrates securely with Google's Gemini models. The API keys are isolated to the server.
*   **Structured Outputs:** The generative roadmap features and "Guru" chat capabilities parse messy LLM text into strictly validated JSON structured output on the backend.
*   **CI/CD Agility:** If we need to alter the motivational tone, modify the RL coach framework, or re-tune the multi-domain curriculum prompts, we update the backend code. That update applies instantaneously across the Web and Mobile ecosystems without requiring application store submissions or web redraws.

## Demonstration Note
If you claim a task on the mobile dashboard now, an asynchronous POST request relays the JWT and intent to FastAPI. The Gamification Engine calculates streak limits, commits changes to PostgreSQL, and returns the XP payload. If the web app is open simultaneously, you will see the exact state parity in milliseconds.
