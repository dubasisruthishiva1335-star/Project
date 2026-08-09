# MyVault — Full Project Scaffold

A fresh, self-contained working scaffold covering all four pieces of MyVault:
`backend` (NestJS API), `admin-web` (Next.js admin console), `landing-web`
(Next.js public site), and `mobile-app` (Flutter student app).

**Important — read this first:** this was rebuilt from scratch in this chat
session, based on your architecture docs. It is **not** the same codebase as
whatever your other Claude Code / Claude session already built (S3, SNS,
Cognito, the full admin controller set, etc.) — that session's files aren't
visible here. This scaffold is deliberately simpler so it actually runs
end-to-end without an AWS account:

- **Auth** is plain JWT (`passport-jwt` + `bcryptjs`), not Cognito.
- **File storage** defaults to local disk (`STORAGE_DRIVER=local`) so you can
  upload notes/results/job postings without any AWS setup. Flip
  `STORAGE_DRIVER=s3` in `backend/.env` and fill in the AWS values once you
  have a bucket, and the same presign/confirm flow switches to real S3 —
  no frontend changes needed.
- **Push notifications** are stubbed (the `/notifications/send` endpoint logs
  instead of calling FCM) — wire in Firebase Admin SDK when you're ready.

Treat this as the runnable foundation to build on, not a drop-in replacement
for a more elaborate AWS setup you may already have.

## What's included

| Folder | Stack | What it does |
|---|---|---|
| `backend/` | NestJS 10 + Prisma + PostgreSQL | Auth, academic content, job listings, results, aptitude, admin upload/confirm endpoints, notifications |
| `admin-web/` | Next.js 14 + Tailwind | Admin login, dashboard, upload pages for Notes / Results / Internships & Jobs |
| `landing-web/` | Next.js 14 + Tailwind | Public marketing page + APK download redirect |
| `mobile-app/` | Flutter + Riverpod + GoRouter | Splash, Login, Register (with hidden dev-settings), Home, Academic Hub |

## Running it locally

The fastest path is Docker Compose, which brings up Postgres + the backend +
both web apps together:

```bash
docker compose up --build
```

- Backend: http://localhost:4000 (Swagger docs at `/api/docs`)
- Admin Web: http://localhost:3001
- Landing site: http://localhost:3000

Then seed some starter data (admin login + a sample student + a subject + two
job listings):

```bash
cd backend
npm install
npx prisma migrate dev --name init
npm run seed
```

Seeded logins:
- **Admin (for admin-web):** hall ticket `ADMIN001`, password `admin123`
- **Student (for the app):** hall ticket `21A91A0501`, password `21A91A0501`

## Running pieces individually

**Backend**
```bash
cd backend
npm install
cp .env.example .env   # edit DATABASE_URL if not using Docker's Postgres
npx prisma migrate dev
npm run start:dev
```

**Admin Web**
```bash
cd admin-web
npm install
cp .env.example .env.local
npm run dev
```
Visit `/login`, sign in with the seeded admin account, then use the sidebar
to reach Notes / Results / Internships & Jobs upload pages.

**Landing site**
```bash
cd landing-web
npm install
npm run dev
```

**Mobile app**
```bash
cd mobile-app
flutter pub get
flutter run
```
The app points at `https://myvault-f08x.onrender.com` by default — double-tap
the MyVault logo on the Login screen to open Developer Settings and switch it
to `http://10.0.2.2:4000` (Android emulator) or your machine's LAN IP while
testing against the local backend.

## What's deliberately left out

To keep this a scaffold you can actually run today rather than a stalled
"almost working" build, these are stubbed or omitted — pick them up when
you're ready:

- Cognito / AWS IAM / S3 CORS policies (your other session's docs cover this
  if you want to migrate to it later — the storage service here is already
  shaped to swap in S3 with just env vars)
- Firebase Cloud Messaging wiring (endpoint shape exists, sending doesn't)
- Offline Hive caching in the Flutter app
- Internship course progression, MCQ auto-grading, certificate generation
- Community chat, live classes, attendance, gamification

## Directory structure

```
myvault-project/
├── docker-compose.yml
├── backend/
│   ├── src/
│   │   ├── auth/           # register, login, JWT strategy, role guard
│   │   ├── academic/       # student-facing: subjects, job listings, results, aptitude
│   │   ├── admin/          # presign + per-domain confirm endpoints
│   │   ├── common/         # storage.service.ts (local disk <-> S3 switch)
│   │   ├── notifications/  # device registration + admin send (stubbed)
│   │   └── prisma/
│   ├── prisma/schema.prisma
│   └── prisma/seed.ts
├── admin-web/
│   ├── app/{login,admin/notes,admin/results,admin/internships}/page.tsx
│   ├── components/admin/UploadForm.tsx
│   └── lib/api-client.ts
├── landing-web/
│   └── app/page.tsx
└── mobile-app/
    └── lib/{core,features/{splash,auth,home,academic_hub}}/
```
