# Costa

Native iOS expense tracker built with SwiftUI. Track spending, scan receipts, and manage costs against the Costa backend (Supabase Auth + Express).

## Features

- **Home** — spending chart, recent costs, and quick access to expense details
- **Add expense** — snap a receipt (camera + AI extraction) or enter manually
- **Edit costs** — update amount, category, date, and notes
- **Auth** — email/password login and Google OAuth via `ASWebAuthenticationSession`
- **Spending & Wallet** — tab shell in place for upcoming views

## Requirements

- Xcode with iOS **26.4** SDK (see `IPHONEOS_DEPLOYMENT_TARGET` in the project)
- A running Costa backend (local or deployed)
- Apple Developer team configured for code signing (`DEVELOPMENT_TEAM` in the Xcode project)

## Getting started

1. Clone the repo:

   ```bash
   git clone https://github.com/abui-am/expense-tracker.git
   cd expense-tracker
   ```

2. Open `costa.xcodeproj` in Xcode.

3. Set your development team under **Signing & Capabilities** if needed.

4. Configure the API base URL (see below).

5. Build and run on a simulator or device (`⌘R`).

## Backend configuration

The app reads `BackendAPIBaseURL` from `Costa-Info.plist`, which is set at build time via the `BACKEND_API_BASE_URL` user-defined build setting in the Xcode project.

| Environment | Value |
|-------------|-------|
| Production (default in project) | `https://costa-i1sj.vercel.app` |
| Local backend | `http://localhost:3222` |

To point at a local server, change `BACKEND_API_BASE_URL` in **Build Settings** for the `costa` target. Local networking is allowed via `NSAllowsLocalNetworking` in `Costa-Info.plist`.

API docs and integration notes live in [`.agents/docs/BE-Integration.md`](.agents/docs/BE-Integration.md) and [`.agents/docs/OAUTH.md`](.agents/docs/OAUTH.md).

## Authentication

- **Email/password** — `POST /api/auth/login`
- **Google OAuth** — opens the backend OAuth flow; the app receives a one-time code on the `costa://oauth` URL scheme and exchanges it via `POST /api/auth/mobile/exchange`
- **Session storage** — access and refresh tokens are stored in the Keychain

## Project structure

```
costa/
├── API/              # Costa API client
├── Auth/             # Login, OAuth, keychain session
├── Configuration/    # API base URL
├── Features/
│   ├── AddExpense/   # Receipt capture, manual entry, edit sheet
│   ├── Home/
│   ├── Login/
│   ├── Spending/
│   └── Wallet/
├── Models/
└── UI/               # Shared form and picker components
```

## Bundle ID & URL scheme

| Setting | Value |
|---------|-------|
| Bundle identifier | `com.abui.costa` |
| OAuth callback scheme | `costa` |

## License

Private — all rights reserved.
