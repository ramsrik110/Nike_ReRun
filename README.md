Nike ReRun
A digital product passport for circular sneakers
Tracking every Nike shoe from manufacture to end-of-life — so returns get sorted, routed, and reported on automatically.

Show Image Show Image Show Image Show Image Show Image Show Image

</div>
The Problem
When a Nike shoe is sold, its supply chain data disappears. Years later, when that shoe comes back for recycling, Nike has no record of what it's made of, no way to sort it efficiently, and no way to prove sustainability/EU compliance to regulators. This is the traceability gap.

The Solution
Nike ReRun gives every shoe a permanent digital identity — from manufacture through return — and uses that data to automatically decide what should happen to it next: refurbish for resale, break down for materials, or recycle. Three connected experiences make that possible:

Customers see their shoe's full digital product passport, initiate a return, and earn NikeCoin rewards.
Hub inspectors scan a returned shoe and get an instant, data-driven routing decision.
Admins see live sustainability metrics — CO₂ saved, throughput, recycling rate — across every hub.
An in-app AI assistant (three personas, one per role) answers questions about the shoe, the routing logic, or the dashboard in natural language.

Features
Customer
Digital Product Passport per shoe (materials, origin, carbon footprint, lifecycle timeline)
One-tap circular return flow with a NikeCoin reward
Personal locker of owned/returned shoes, profile stats, and eco achievement badges
NikeBot chat assistant — explains passport data, routing status, and rewards
Hub Inspector
Employee ID + PIN "punch in" flow styled for a handheld scanner, independent from the customer/admin login
QR / shoe-ID scan → material & condition breakdown → one-tap routing decision
Shift stats (scans, throughput) and routing history log
RouteBot chat assistant — explains the routing matrix and hub status
Admin
Live sustainability dashboard: CO₂ saved, shoes processed, recycling %, active hubs
Region filters (Global / Europe / North America) with monthly trend charts
EU compliance report generation (PDF)
DashBot chat assistant — summarizes dashboard metrics on demand
Shared
Dark/light theme toggle for Customer & Admin; a separate monochrome factory-tool theme for Inspector
Adjustable font scale for accessibility
Nike-grade motion: staggered fade/slide-in animations, spring physics, accent glow on active elements
Tech Stack
Layer	Technology
App framework	Flutter (Dart)
Backend / database	Firebase (Cloud Firestore, Firebase Auth)
AI chat	Groq API — Llama 3.3 70B (chat), Whisper large-v3 (speech-to-text)
Text-to-speech	flutter_tts
Scanning	mobile_scanner, google_mlkit_image_labeling
Animation	flutter_animate, lottie, confetti
Reporting	pdf, printing
Typography	Google Fonts — Bebas Neue (headings), Nunito (body)
Automation	Make.com
Architecture
lib/
├── main.dart                     # App entry, theming, auth gate, shell routing
├── firebase_options.dart         # FlutterFire-generated config
├── nike_colors.dart               # Theme colors (dark/light/inspector) as a ThemeExtension
├── theme_notifier.dart            # App-wide + inspector-only dark/light mode state
├── font_scale_notifier.dart       # Accessibility font scaling
│
├── models/
│   ├── customer_model.dart
│   ├── hub_model.dart
│   └── shoe_model.dart
│
├── screens/
│   ├── login_screen.dart                  # Customer/Admin sign-in
│   ├── register_screen.dart               # Customer sign-up
│   ├── inspector_punch_in_screen.dart      # Inspector ID + PIN entry
│   ├── inspector_register_screen.dart
│   ├── customer_landing_screen.dart
│   ├── customer_locker_screen.dart         # Owned shoes + digital product passport
│   ├── customer_return_confirm_screen.dart
│   ├── customer_return_success_screen.dart
│   ├── customer_profile_screen.dart
│   ├── hub_inspector_screen.dart           # Scan + routing trigger
│   ├── hub_result_screen.dart              # Routing decision output
│   ├── inspector_profile_screen.dart
│   ├── admin_profile_screen.dart
│   └── dashboard_screen.dart               # HQ sustainability dashboard
│
├── services/
│   ├── firebase_service.dart      # All Firestore reads/writes
│   ├── chatbot_service.dart       # Groq LLM calls, persona prompts, TTS
│   ├── chatbot_config.dart        # API keys / model config (gitignored)
│   └── report_service.dart        # PDF compliance report generation
│
├── utils/
│   ├── routing_algorithm.dart     # Sole/fabric condition → routing decision logic
│   └── region_utils.dart
│
└── widgets/
    ├── chatbot_widget.dart        # Floating chat FAB + panel, shared by all 3 personas
    └── nav_controls.dart          # Shared nav drawer / bottom nav
Authentication
Two separate entry points, matched to how each persona actually uses the app:

Customer & Admin → lib/screens/login_screen.dart, standard email/password, with links to register or to the inspector punch-in screen.
Inspector → lib/screens/inspector_punch_in_screen.dart, Employee ID + 4-digit PIN on a large numeric keypad, designed for a handheld scanner device on a warehouse floor. Internally still backed by a normal Firebase email/password account — the ID/PIN is just a friendlier front end.
Routing Algorithm
Given a scanned shoe's sole and fabric condition, the hub inspector gets an instant routing decision:

Sole	Fabric	Decision
Intact	Intact	Refurbish for resale
Damaged	Intact	Flyknit textile re-weaving
Intact	Damaged	Nike Grind rubber shredding
Damaged	Damaged	Thermoplastic pelletizing
Material composition percentages (Flyknit / Rubber / Foam / Leather) refine the sub-stream selection within each route.

AI Assistant
Each role gets its own chat persona, wired to real Firestore data for that role:

Persona	Role	Knows about
NikeBot	Customer	This shoe's passport, lifecycle status, NikeCoin rewards
RouteBot	Inspector	Routing matrix, current hub status/throughput
DashBot	Admin	Global sustainability metrics, hub network stats
Text chat runs on Groq's Llama 3.3 70B; responses are read aloud via flutter_tts. Voice input (Groq Whisper) is tap-to-activate — no always-listening wake word, by design (browsers block always-on mic access without a user gesture).

Data Model (Firestore)
Collection	Purpose	Key fields
Shoes	One doc per physical shoe — the digital product passport	SUID, material composition (MCP-*), ECO-CO2, LCS-STS (lifecycle status), RTE-DCN (routing decision)
users	Customer & inspector accounts	Name, email, linked shoes, NikeCoin balance
hubs	Recycling hub network	Location, lanes, throughput, routing log
dashboard	Aggregated sustainability metrics	Total CO₂, throughput, recycling %, active hub count
Getting Started
Install Flutter (SDK ^3.11.5).
Clone the repo and fetch dependencies:
flutter pub get
Add your own Firebase project config via the FlutterFire CLI:
flutterfire configure
Copy lib/services/chatbot_config.example.dart to lib/services/chatbot_config.dart and add a Groq API key.
Run the app:
flutter run
Team
Name	Role
Rajvardhan Anil Delekar	Product Owner — UI/UX, FlutterFlow designs, Jira management
Ram Sri Karan Mylavarapu	Scrum Master — Lead Developer (Flutter, Firebase, routing algorithm)
Stacia Agusta D'Silva	Frontend architecture, QA testing, GitHub management, recycle score algorithms
