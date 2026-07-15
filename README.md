# ♻️ Nike ReRun — Digital Product Passport for Circular Sneakers

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Groq](https://img.shields.io/badge/Groq_API-F55036?style=for-the-badge&logo=groq&logoColor=white)
![Llama 3](https://img.shields.io/badge/Llama_3.3_70B-0452C8?style=for-the-badge&logo=meta&logoColor=white)
![Make.com](https://img.shields.io/badge/Make.com-000000?style=for-the-badge&logo=make&logoColor=white)

> A modern, AI-powered circular economy application designed to close the fashion supply chain "traceability gap". By equipping every physical sneaker with an immutable Digital Product Passport (DPP), Nike ReRun manages reverse logistics, executes weighted recycling routing, and generates real-time compliance dashboards.

---

## 📌 Table of Contents
1. [The Traceability Gap](#-the-traceability-gap)
2. [The Solution & Core Workflows](#-the-solution--core-workflows)
3. [System Architecture](#%EF%B8%8F-system-architecture)
4. [The Routing & Recycle Score Algorithm](#-the-routing--recycle-score-algorithm)
5. [AI Chatbot Infrastructure](#-ai-chatbot-infrastructure)
6. [Database Schema (Firestore)](#-database-schema-firestore)
7. [Authentication Entry Points](#-authentication-entry-points)
8. [The Development Team & Contributions](#-the-development-team--contributions)
9. [Getting Started](#-getting-started)

---

## 🛑 The Traceability Gap
In the current linear retail model, the moment a Nike sneaker is purchased, its supply chain data ceases to exist. Years down the line, when that shoe is returned for recycling, Nike lacks critical item-level insight:
* **No Material Integrity Records:** No way to instantly know the material composition ratios (leather, flyknit, rubber, foam) of that specific production run.
* **Inclusion Barriers:** Inefficient sorting procedures that rely on manual inspection, leading to sorting errors.
* **Compliance Risks:** Difficulty proving verified carbon offsets and circular recycling rates to EU regulatory bodies.

### 💡 The ReRun Solution
Nike ReRun establishes a continuous, end-to-end data pipeline:
1. **At Manufacture:** Every physical sneaker is assigned a unique **SUID** linked to an immutable Digital Product Passport in Firebase.
2. **At Return:** The customer is incentivized to return the shoe via automated **NikeCoin rewards**.
3. **At the Sorting Hub:** Inspectors scan the shoe to execute a weighted, multi-level routing algorithm.
4. **At HQ:** Sustainability metrics compile in real-time, allowing administrators to generate certified EU compliance reports in one click.

---

## 📱 Core Workflows

### 👤 1. Customer Hub
* **Digital Product Passport:** Access the manufacturing origin, verified carbon footprint ($CO_2$ saved), and a dynamic three-milestone lifecycle timeline.
* **Circular Return Engine:** Tap to initiate returns, triggering instant wallet credit of **120 NikeCoin rewards** to drive return loops.
* **Personal Digital Locker:** Manage actively owned and historically recycled shoes alongside gamified eco-achievement badges.
* **NikeBot AI:** Answer customer inquiries regarding their specific shoe's materials, return eligibility, and rewards.

### 🏭 2. Hub Inspector Terminal
* **Industrial Grade UI:** Transition into a high-contrast, monochrome, low-light factory-optimized interface tailored for handheld rugged warehouse scanners.
* **QR Smart Scanner:** Seamlessly integrates physical cameras to pull up active design blueprints, structural condition meters, and material breakdowns.
* **Algorithmic Routing:** Evaluates physical sole and fabric conditions through an active decision matrix.
* **RouteBot AI:** Instant helper trained on standard operating procedures, logistics streams, and mechanical throughput benchmarks.

### 📈 3. Admin HQ Dashboard
* **Macro Sustainability Analytics:** Monitor global or regionalized aggregate metrics including total tonnage of $CO_2$ diverted, active hub counts, and total shoes processed.
* **Interactive Filters:** Narrow performance trends by Global, European, or North American facilities.
* **Instant Compliance:** Generate and export official regulatory PDFs proving verified circular recycling statistics.
* **DashBot AI:** Summarizes complex operational data, regional trends, and logistics patterns on command.

---

## 🏗️ System Architecture

The codebase utilizes a clean, decoupled structure to segregate UI rendering, state management, global models, and persistent services:

```text
lib/
├── main.dart                      # App entry, dark/light/inspector themes, & auth router
├── firebase_options.dart          # Local Firebase environment variables
├── nike_colors.dart               # Theme extensions (Standard Light/Dark & Industrial Monochrome)
├── theme_notifier.dart             # App-wide visual theme state controller
├── font_scale_notifier.dart        # Global accessibility configuration for text sizing
│
├── models/                        # Declarative system schemas
│   ├── customer_model.dart        # Customer profile, wallet, and badges
│   ├── hub_model.dart             # Recycling hub properties and historical logs
│   └── shoe_model.dart            # SUID mapping, materials, and DPP timeline data
│
├── screens/                       # Presentation layer
│   ├── login_screen.dart          # Customer & Admin multi-login portal
│   ├── register_screen.dart       # Customer onboarding setup
│   ├── inspector_punch_in_screen.dart # Employee ID & PIN handheld login keypad
│   ├── inspector_register_screen.dart # Internal factory worker enrollment
│   ├── customer_landing_screen.dart   # Interactive customer menu & locker access
│   ├── customer_locker_screen.dart    # Digital Product Passport rendering
│   ├── customer_return_confirm_screen.dart 
│   ├── customer_return_success_screen.dart # Incentive payout interface
│   ├── customer_profile_screen.dart
│   ├── hub_inspector_screen.dart      # Scanner viewfinder and condition evaluation tools
│   ├── hub_result_screen.dart         # Final routing decision and logic breakdown
│   ├── inspector_profile_screen.dart  # Shift statistics and processing log history
│   ├── admin_profile_screen.dart
│   └── dashboard_screen.dart          # Headquarters analytics panel
│
├── services/                      # System business logic & platform wrappers
│   ├── firebase_service.dart      # Centralized database reader/writer layer
│   ├── chatbot_service.dart       # Groq client integration (Whisper & Llama 3.3 70B)
│   ├── chatbot_config.dart        # Secure API settings (gitignored)
│   └── report_service.dart        # Document generation module
│
├── utils/                         # Mathematical & functional utilities
│   ├── routing_algorithm.dart     # Sole/fabric matrix logic
│   └── region_utils.dart
│
└── widgets/                       # Reusable visual components
    ├── chatbot_widget.dart        # Floating conversational overlay (all roles)
    └── nav_controls.dart          # Adaptive navigation menus and drawers
🔀 The Routing & Recycle Score AlgorithmWhen a returned shoe is processed, the system runs a two-step routing pipeline:Step 1: Decision Matrix (Top-Level Stream)The system checks the structural integrity of the sole and the fabric to determine the primary logistics route:Sole ConditionFabric ConditionBase Routing DecisionLogistics OutcomeIntactIntact📦 Refurbish for ResaleReturned to premium circular store shelvesDamagedIntact🧵 Flyknit Textile Re-WeavingStripped for yarn spinning & textile recoveryIntactDamaged👟 Nike Grind Rubber ShreddingConverted to playground or athletic turfDamagedDamaged♻️ Thermoplastic PelletizingBroken down to base chemical polymersStep 2: Recycle Score Calculation (Material Refinement)Once the base route is selected, the application refines the material output using physical material weight percentages. A custom Recycle Score is calculated to direct the batch to the exact sub-stream. This calculation dynamically weighs each material's density (Flyknit, Rubber, Foam, and Leather) against standard processing values to determine the ideal sorting sub-lane.🤖 AI Chatbot InfrastructureThe application features three conversational agents powered by a single, multi-persona pipeline using Groq API's Llama 3.3 70B model and Whisper large-v3 for voice processing:[User Input: Text or Voice] 
       │
       ▼ (Speech-to-Text via Whisper)
[Central Chatbot Service]
       │
       ├─────► [If Customer Profile] ──► Inject NikeBot System Prompt + SUID Passport Info
       ├─────► [If Hub Inspector]  ──► Inject RouteBot System Prompt + Hub Throughput Metrics
       └─────► [If System Admin]   ──► Inject DashBot System Prompt + Global Regional KPIs
       │
       ▼
 [Llama 3.3 70B Context Evaluation]
       │
       ▼ (Text Response & Local Speech Synthesis via Flutter TTS)
[Natural Language Output]
🤖 AI Assistant Persona ScopePersonaRoleKnowledge BaseNikeBotCustomerThis specific shoe's passport, lifecycle status, and NikeCoin rewards.RouteBotInspectorThe routing matrix, current hub status, and throughput data.DashBotAdminGlobal sustainability metrics and hub network stats.🗄️ Database Schema (Firestore)The application relies on a strictly structured, document-relational model within Cloud Firestore:Plaintext/Shoes (Collection)
   ├── SUID {string} [Document ID]
   ├── modelName {string}
   ├── materialComposition {map}
   │     ├── MCP_Flyknit {number}
   │     ├── MCP_Rubber {number}
   │     ├── MCP_Foam {number}
   │     └── MCP_Leather {number}
   ├── carbonFootprint {number}
   ├── lifecycleStatus {string}
   └── currentRoute {string}

/users (Collection)
   ├── userID {string} [Document ID]
   ├── name {string}
   ├── email {string}
   ├── role {string} [customer / inspector / admin]
   ├── walletBalance {number}
   └── linkedShoes {array}

/hubs (Collection)
   ├── hubID {string} [Document ID]
   ├── location {string}
   ├── processingCapacity {number}
   ├── currentThroughput {number}
   └── activeLanes {number}

/dashboard (Collection)
   ├── statID {string} [Document ID]
   ├── totalCarbonDiverted {number}
   ├── aggregateRecyclingRate {number}
   └── totalProcessedCount {number}
🔑 Authentication Entry PointsAuthentication is split to match real-world operational scenarios:Consumer & Executive Gateway (login_screen.dart): Standard, secure email-and-password portal with options for self-onboarding registration.Industrial Operator Portal (inspector_punch_in_screen.dart): Keypad-based punch-in screen utilizing an Employee ID and a 4-digit PIN designed specifically for warehouse use. (Under the hood, this translates securely into credentialed Firebase sessions to prevent data vulnerabilities).👥 The Development Team & ContributionsThis application was engineered by a dedicated three-person project team. Below is the detailed breakdown of our individual roles and system contributions:🎨 Rajvardhan Anil DelekarRole: Product Owner & Lead UI/UX DesignerDesign Systems: Built the full visual style, choosing a premium dark background with fluorescent lime green accents to create a high-end sport aesthetic.Responsive Layouts: Designed the interface for all three roles, ensuring proper scaling across both standard consumer smartphones and rugged factory handheld tools.User Experience (UX): Maintained user-centered agile priorities through detailed sprint planning, mockups, and card-based structural navigation layouts.🛠️ Ram Sri Karan MylavarapuRole: Scrum Master & Lead DeveloperData Layer Engineering: Designed and coded the entire Firestore data pipeline (firebase_service.dart), managing live collections and real-time state synchronization.Algorithms: Authored the multi-level decision matrix and weighted physical routing algorithms (routing_algorithm.dart).Integrations: Configured the asynchronous API handlers linking the mobile frontend to the Groq Llama and Whisper engines.Scrum Management: Coordinated developer timelines, managed continuous integration, and ran daily checks to merge UI/UX design components with backend services.📐 Stacia Agusta D'SilvaRole: Frontend Architect & Quality AssuranceStructural Architecture: Developed the clean "Shell" rendering system to safely run parallel interface workflows without file conflicts.Physical Processing Logic: Engineered the mathematical models responsible for scaling compound Material Composition Percentages into compliant recycling classifications.Quality Assurance & Performance: Conducted testing, managed local emulator configurations, and resolved Git version conflicts.🚀 Getting StartedTo spin up a local instance of Nike ReRun for testing, ensure your machine has Flutter SDK version ^3.11.5 or newer installed.Clone the Repository:Bashgit clone [https://github.com/ramsrik110/Nike_ReRun.git](https://github.com/ramsrik110/Nike_ReRun.git)
cd Nike_ReRun
Acquire Dependencies:Bashflutter pub get
Initialize Firebase Services:Make sure you have the FlutterFire CLI installed on your system, then run:Bashflutterfire configure
Add API Credentials:Duplicate the file lib/services/chatbot_config.example.dart and name it lib/services/chatbot_config.dart.Paste your active Groq API Key into the variable placeholder.Deploy & Debug:Ensure you have a simulator running or a physical device connected, then launch:Bashflutter run
