# Trabab Admin Dashboard

This is the enterprise-level admin dashboard for the Trabab / AirMass application.

## Tech Stack

- **Framework**: Next.js 14+ (App Router)
- **Styling**: TailwindCSS + Shadcn/UI
- **State Management**: Zustand (Global UI), TanStack Query (Server State)
- **Networking**: Axios
- **Charts**: Recharts
- **Forms**: React Hook Form + Zod

## Getting Started

1.  Navigate to the `admin-dashboard` directory:
    ```bash
    cd admin-dashboard
    ```

2.  Install dependencies:
    ```bash
    npm install
    ```

3.  Configure environment:
    - Copy `.env.example` to `.env.local` (or create one).
    - Set `NEXT_PUBLIC_API_URL` to your Go backend URL (default: `http://localhost:8080/api`).

4.  Run the development server:
    ```bash
    npm run dev
    ```

5.  Open [http://localhost:3000](http://localhost:3000) with your browser.

## Features

- **User Management**: View, search, and manage users.
- **Auction Management**: Approve/reject auctions, view details.
- **Store Management**: Manage Verified Sellers and stores.
- **Analytics**: Visualize store performance metrics.
- **Settings**: Configure app-wide settings and feature toggles.

## Project Structure

- `src/app`: Next.js App Router pages.
- `src/components/ui`: Shadcn UI components.
- `src/components/layout`: Sidebar and Layout components.
- `src/features`: Feature-based modules (api services, specific components).
    - `auth`: Login logic.
    - `users`: User management tables and services.
    - `auctions`: Auction management.
    - `stores`: Store management.
    - `analytics`: Dashboard charts.
- `src/lib`: Utilities and API client.
- `src/store`: Global Zustand store.
- `src/types`: Shared TypeScript interfaces.

## Backend Integration

The dashboard is configured to talk to the Go backend via `src/lib/api.ts`.
Ensure your backend is running and CORS is configured to allow requests from `http://localhost:3000`.
Authentication is handled via JWT stored in localStorage.
