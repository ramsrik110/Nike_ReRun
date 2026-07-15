# ♻️ Nike ReRun — Digital Product Passport for Circular Sneakers

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Groq](https://img.shields.io/badge/Groq_API-F55036?style=for-the-badge&logo=groq&logoColor=white)
![Llama 3](https://img.shields.io/badge/Llama_3.3_70B-0452C8?style=for-the-badge&logo=meta&logoColor=white)

Tracking every Nike shoe from manufacture to end-of-life — so returns get sorted, routed, and reported on automatically. 

---

### 🛑 The Problem: The Traceability Gap
When a Nike shoe is sold, its supply chain data disappears. Years later, when that shoe comes back for recycling, Nike has no record of what it's made of, no way to sort it efficiently, and no way to prove sustainability/EU compliance to regulators. 

### 💡 The Solution
**Nike ReRun** gives every shoe a permanent digital identity — from manufacture through return — and uses that data to automatically decide what should happen to it next: refurbish for resale, break down for materials, or recycle. 

---

## ✨ Core Experiences & Features

### 👤 1. Customer Experience
* **Digital Product Passport:** View shoe materials, origin, carbon footprint, and lifecycle timeline.
* **Circular Returns:** One-tap return flow that rewards users with **NikeCoin**.
* **Personal Locker:** Manage owned/returned shoes, view profile stats, and collect eco-achievement badges.
* **NikeBot (AI):** A chat assistant that explains passport data, routing status, and rewards.

### 🏭 2. Hub Inspector (Factory Tool)
* **Industrial UI:** Monochrome factory-tool theme with an Employee ID + PIN "punch in" flow styled for handheld scanners.
* **Smart Scanning:** QR/shoe-ID scan instantly pulls up material & condition breakdown.
* **One-Tap Routing:** Executes instant, data-driven routing decisions based on physical condition.
* **RouteBot (AI):** A chat assistant that explains the routing matrix and current hub status.

### 🌍 3. Admin / HQ Dashboard
* **Live Sustainability Metrics:** Track CO₂ saved, total shoes processed, recycling %, and active hubs in real-time.
* **Dynamic Filtering:** Filter data by Region (Global / Europe / North America) with monthly trend charts.
* **EU Compliance:** Generate instant PDF reports for regulatory compliance.
* **DashBot (AI):** A chat assistant that summarizes dashboard metrics on demand.

---

## 🔀 The Routing Algorithm Matrix

Given a scanned shoe's condition, the app instantly calculates its recycling route. *Material composition percentages (Flyknit / Rubber / Foam / Leather) further refine the sub-stream selection within each route.*

| Sole Condition | Fabric Condition | Routing Decision |
| :--- | :--- | :--- |
| **Intact** | **Intact** | 📦 Refurbish for resale |
| **Damaged** | **Intact** | 🧵 Flyknit textile re-weaving |
| **Intact** | **Damaged** | 👟 Nike Grind rubber shredding |
| **Damaged** | **Damaged** | ♻️ Thermoplastic pelletizing |

---

## 🤖 AI Assistant Architecture
Each role gets its own chat persona, wired directly to real Firestore data. Text chat runs on **Groq's Llama 3.3 70B** with voice input via **Whisper large-v3** and text-to-speech via `flutter_tts`.

| Persona | Role | Knowledge Base |
| :--- | :--- | :--- |
| **NikeBot** | Customer | This specific shoe's passport, lifecycle status, and NikeCoin rewards. |
| **RouteBot** | Inspector | The routing matrix, current hub status, and throughput data. |
| **DashBot** | Admin | Global sustainability metrics and hub network stats. |

---

## 🗄️ Data Model (Firestore)

| Collection | Purpose | Key Fields |
| :--- | :--- | :--- |
| `Shoes` | Digital product passport per physical shoe | `SUID`, material composition, `ECO-CO2`, lifecycle status, routing decision |
| `users` | Customer & Inspector accounts | Name, email, linked shoes, NikeCoin balance |
| `hubs` | Recycling hub network | Location, lanes, throughput, routing log |
| `dashboard` | Aggregated sustainability metrics | Total CO₂, throughput, recycling %, active hub count |

---

## 🏗️ Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend:** Firebase (Cloud Firestore, Firebase Auth)
* **AI & Voice:** Groq API (Llama 3.3 70B, Whisper), `flutter_tts`
* **Hardware Integrations:** `mobile_scanner`, `google_mlkit_image_labeling`
* **UI/UX:** `flutter_animate`, `lottie`, Google Fonts (Bebas Neue & Nunito)
* **Reporting:** `pdf`, `printing`
* **Automation:** Make.com

---

## 🚀 Getting Started

1. **Install Flutter** (SDK `^3.11.5`).
2. **Clone the repo** and fetch dependencies:
   ```bash
   flutter pub get
