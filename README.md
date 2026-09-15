# FairGo — Fair, Transparent & Reliable Mobility

> **A modern, multimodal ride-hailing, driver-hire, and parcel delivery platform built for everyday commuters and drivers across India.**

---

## 🌟 About FairGo

FairGo is a next-generation mobility platform designed around a simple, powerful promise: **fair fares for riders, dignity and sustainable earnings for drivers, and complete transparency for everyone.**

Unlike traditional ride-hailing platforms with volatile 4x–5x surges, hidden commissions, and arbitrary cancellations, FairGo offers predictable fares, zero hidden fees, and transparent surge caps. Whether you need a quick scooter ride through city traffic, an auto for your daily commute, a comfortable sedan for family travel, an intercity courier, or a verified chauffeur to drive your own car, FairGo gets you there smoothly.

---

## 🚗 Services Offered

| Service | Description | Ideal For |
| :--- | :--- | :--- |
| 🛵 **FairGo Bike** | Quick, affordable two-wheeler rides dodging urban traffic jams. | Solo commuters, short hops, and budget travel. |
| 🛺 **FairGo Auto** | Doorstep auto-rickshaw pickup with digital meters and upfront fares. | Everyday city transit without haggling. |
| 🚗 **FairGo Cab (Mini / Sedan / SUV)** | Air-conditioned cabs across Economy, Comfort Sedan, and Spacious SUV. | Airport runs, family outings, and corporate commutes. |
| 📦 **FairGo Parcel Delivery** | Same-day doorstep parcel pickup and delivery with live tracking and PIN delivery confirmation. | Documents, packages, business deliveries, and gifts. |
| 🧑‍✈️ **Book-a-Driver (Driver Hire)** | Hire professional, verified drivers on an hourly or daily basis to drive your own personal vehicle. | Long road trips, late-night dinners, hospital visits, and weekend getaways. |
| 📅 **Scheduled Rides** | Reserve rides up to 7 days in advance with guaranteed driver dispatch. | Early morning airport departures and critical appointments. |

---

## 🛡️ Safety & Trust

- **24/7 GPS Tracking**: Every trip is tracked in real-time from start to destination.
- **One-Tap Emergency SOS**: Instant alert triggering emergency contacts and local authorities with live coordinates.
- **Trip Sharing**: Share your live ride progress and driver details with friends and family via a single link.
- **Start-of-Trip OTP Verification**: Trips only start when you share your secure 4-digit PIN with the driver.
- **Verified Drivers & Clean Vehicles**: Complete KYC background checks, driving license verification, and vehicle fitness validation.

---

## 💬 Modern 24/7 Customer Support Experience

FairGo features an intuitive, **context-first support hub** designed to solve issues immediately without making you jump through hoops:

- **Instant Self-Help**: Proactive solutions and FAQs categorized by Trip, Fare & Payments, Account, and Safety.
- **Live Support Chat**: Connect directly with support specialists for real-time resolution, typing indicators, image uploads, and post-chat satisfaction ratings.
- **Phone Callback**: Request a callback within a convenient 15-minute window if you prefer speaking to an agent.
- **Email Support Tickets**: Submit detailed tickets with screenshots, and track status with human-friendly reference IDs (e.g., `#FG-2026-10482`).

---

## 📱 The Mobile Applications

FairGo comes with two dedicated mobile apps built for cross-device responsiveness (compact phones, large devices, tablets, and web):

1. **Rider App (`apps/rider_mobile`)**:
   - Modern warm terracotta and cream design aesthetic with playful custom retro illustrations.
   - Interactive 3D isometric city previews and map routing.
   - 1-tap ride selection, multimodal route comparisons, and wallet management.

2. **Driver Partner App (`apps/driver_mobile`)**:
   - Clean, focused interface optimized for on-the-road safety.
   - Online/Offline availability toggle with real-time incoming trip requests and audio chimes.
   - Daily earnings summaries, weekly payout tracking, and performance tiers.

---

## 🚀 How to Run the Applications

### Step 1: Set Up the Supabase Database

1. Open your [Supabase Dashboard](https://app.supabase.com/) and create or select your project.
2. Go to the **SQL Editor** tab on the left menu (`>_ SQL Editor`).
3. Click **"New query"**.
4. Open the [`supabase_schema.sql`](./supabase_schema.sql) file from this repository, copy its contents, paste them into the Supabase SQL Editor, and click **"Run"**.
5. All database schemas, tables, spatial indexes, stored procedures, and initial seed data will be created instantly.

---

### Step 2: Where to Give Your Supabase Credentials

#### 1. Backend Microservices:
In the project root, duplicate `.env.example` to `.env`:
```bash
cp .env.example .env
```
Fill in your Supabase connection parameters (found in **Supabase Dashboard > Project Settings > Database** and **Project Settings > API**):
```env
# Database Connection
DATABASE_URL=postgresql://postgres.[YOUR-PROJECT-REF]:[YOUR-PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres?pgbouncer=true

# API Access
SUPABASE_URL=https://[YOUR-PROJECT-REF].supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### 2. Mobile Applications (Flutter):
You can pass your credentials at runtime or configure them in the constants file:

- **Option A (Recommended — command line define):**
  ```bash
  flutter run --dart-define=SUPABASE_URL=https://[YOUR-PROJECT-REF].supabase.co --dart-define=SUPABASE_ANON_KEY=[YOUR-ANON-KEY]
  ```

- **Option B (Direct file configuration):**
  Open [`apps/rider_mobile/lib/core/constants/app_constants.dart`](apps/rider_mobile/lib/core/constants/app_constants.dart) and update:
  ```dart
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://[YOUR-PROJECT-REF].supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '[YOUR-ANON-KEY]',
  );
  ```

---

### Step 3: Run the Rider App

Ensure Flutter is installed on your system (`flutter doctor`).

```bash
# Navigate to Rider Mobile
cd apps/rider_mobile

# Fetch dependencies
flutter pub get

# Launch app on Chrome, Connected Android/iOS Device, or Simulator
flutter run
```

To run on Chrome (Web view):
```bash
flutter run -d chrome
```

---

### Step 4: Run the Driver App

```bash
# Navigate to Driver Mobile
cd apps/driver_mobile

# Fetch dependencies
flutter pub get

# Launch app
flutter run
```

---

### Step 5: (Optional) Run the Backend Microservices Locally

```bash
# In the root directory, install monorepo dependencies
pnpm install

# Build all TypeScript packages and services
pnpm build

# Start the Support Service (includes live agent console at http://localhost:3007)
cd services/support
npm start
```

---

## 📄 License & Community

Built with fair principles for the future of urban transit in India.
