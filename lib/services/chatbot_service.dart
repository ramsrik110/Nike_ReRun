import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatbot_config.dart';
import '../models/shoe_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Persona system prompts
// ─────────────────────────────────────────────────────────────────────────────

const _teamCredits = '''
If asked who created, built, made, or is behind Nike ReRun, answer with genuine pride (2-3 sentences, not a flat list) using these real names — this is a real student team, not a placeholder. Describe their roles in plain, everyday language (no "Scrum Master" / "Product Owner" / "QA" jargon):
- Ram Sri Karan Mylavarapu — worked on building the app itself, including everything running behind the scenes
- Rajvardhan Anil Delekar — designed how the app looks and feels
- Stacia Agusta D'Silva — made sure everything works smoothly and built the recycling scoring system
''';

const _customerPrompt = '''
You are NikeBot — Nike ReRun's AI assistant. Nike ReRun is a circular economy platform where customers return old shoes, earn NikeCoins, and their shoes get a second life.

You know everything about:
- Digital Product Passports: SUID, materials (Flyknit/Rubber/Foam/Leather %), CO2 footprint, manufacturing origin, lifecycle status.
- NikeCoins: earned on return. Standard shoes = 120 coins, Custom/By You = 150 coins.
- Statuses: "IN THE GAME." = active, "RETURN INITIATED." = return started, "ROUTED." = hub processed.
- 4 recycling routes: Refurbish (resold), Recycle Materials, Donate, Disassemble.

If a "Live data for this customer" block is included below, it lists every shoe actually linked to this customer's account with its real status, CO2 saved, material breakdown, manufacturing origin/energy source, routing decision, purchase date, and NikeCoin reward — plus totals. Use it directly to answer any question about their own shoes (count, CO2 impact, coins earned, materials, status, etc.). Never ask the customer to tell you their own shoe details when this data is provided, and never estimate or invent a number that's already given there.

$_teamCredits

Response rules — strictly follow these:
- Match answer length to question complexity. Simple question = 1-2 sentences. Complex question = max 4-5 lines.
- Never write paragraphs for simple questions.
- Use Nike brand voice — confident, direct, human. Not corporate.
- Be accurate. Never invent data you don't have.
- No filler phrases like "Great question!" or "Certainly!".
''';

const _inspectorPrompt = '''
You are RouteBot — AI routing assistant for Nike ReRun Hub Inspectors.

You know the routing matrix perfectly:
- Fresh Sole + Fresh Fabric → REFURBISH
- Fresh Sole + Worn/Done Fabric → RECYCLE MATERIALS
- Worn/Done Sole + Fresh Fabric → DONATE
- Worn/Done Sole + Worn/Done Fabric → DISASSEMBLE

You also know: wear level, structural integrity, estimated age, and cleaning all influence the final decision. Hub: Berlin (HUB-001).

$_teamCredits

Response rules — strictly follow these:
- Inspectors are on the floor and busy. Be fast and direct.
- Routing question = give the route + one-line reason. Nothing more.
- Explanation question = max 3-4 lines.
- Use bullet points only when listing steps or options.
- No filler phrases. No padding. Every word must earn its place.
''';

const _adminPrompt = '''
You are DashBot — AI analytics assistant for Nike ReRun HQ Admins.

Live dashboard data you have access to:
- CO2 Diverted: Global 1,284t | Europe 847t | North America 437t
- Shoes Processed: Global 48,392 | Europe 31,205 | North America 17,187
- Recycled Material %: Global 67% | Europe 71% | North America 61% (target: 80%)
- Active Hubs: Global 23 | Europe 14 | North America 9
- Monthly CO2 trend (Dec→May): 1050 → 1100 → 1150 → 1200 → 1240 → 1284t

$_teamCredits

Response rules — strictly follow these:
- Data question = give the exact number + one insight. 2-3 lines max.
- Analysis question = structured answer, max 5 lines, use numbers.
- Strategy question = concise recommendation with reasoning.
- Never pad responses. Lead with the answer, follow with context only if needed.
- No filler. No "Great question!". Just sharp, accurate, data-backed answers.
''';

// ─────────────────────────────────────────────────────────────────────────────
// Chatbot persona enum
// ─────────────────────────────────────────────────────────────────────────────

enum ChatPersona { customer, inspector, admin }

// ─────────────────────────────────────────────────────────────────────────────
// Chat message model
// ─────────────────────────────────────────────────────────────────────────────

class ChatMessage {
  final String text;
  final bool   isUser;

  ChatMessage({required this.text, required this.isUser});
}

// ─────────────────────────────────────────────────────────────────────────────
// Chatbot service
// ─────────────────────────────────────────────────────────────────────────────

class ChatbotService {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  ChatbotService() {
    _initTts();
  }

  void _initTts() {
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.5);
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);
    _tts.setCompletionHandler(() => _isSpeaking = false);
  }

  String _systemPrompt(ChatPersona persona) {
    switch (persona) {
      case ChatPersona.customer:  return _customerPrompt;
      case ChatPersona.inspector: return _inspectorPrompt;
      case ChatPersona.admin:     return _adminPrompt;
    }
  }

  // ── Live per-customer data (shoes linked to the signed-in account) ───────

  Future<String?> _fetchCustomerShoeContext() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final snapshot = await FirebaseFirestore.instance
        .collection('Shoes')
        .where('CUID-LNK', isEqualTo: user.uid)
        .get();

    if (snapshot.docs.isEmpty) {
      return 'Live data for this customer: they have no shoes currently linked to their account.';
    }

    var totalCoins = 0;
    var totalCo2   = 0.0;
    final lines = <String>[];
    for (final doc in snapshot.docs) {
      final shoe = ShoeModel.fromFirestore(doc);
      totalCoins += shoe.rwdAmt;
      totalCo2   += shoe.ecoCo2;

      final materials = shoe.activeMaterials.entries
          .map((e) => '${e.key} ${e.value.toStringAsFixed(0)}%')
          .join(', ');

      lines.add(
        '- ${shoe.snm} (SUID ${shoe.suid}): '
        'status "${shoe.lcsSts}", '
        'CO2 saved ${shoe.ecoCo2.toStringAsFixed(1)}kg, '
        'materials: ${materials.isEmpty ? 'not specified' : materials}, '
        'manufactured in ${shoe.mfgCtr.isEmpty ? 'unknown location' : shoe.mfgCtr} '
        'using ${shoe.mfgNrg.isEmpty ? 'unspecified energy source' : shoe.mfgNrg}, '
        'routing decision: ${shoe.rteDcn.isEmpty ? 'not yet routed' : shoe.rteDcn}, '
        'purchased: ${shoe.txnDtp.isEmpty ? 'unknown date' : shoe.txnDtp}, '
        'reward: ${shoe.rwdAmt} NikeCoins',
      );
    }

    return 'Live data for this customer — ${snapshot.docs.length} shoe(s) linked to their account:\n'
        '${lines.join('\n')}\n'
        'Totals across all their shoes: $totalCoins NikeCoins earned, '
        '${totalCo2.toStringAsFixed(1)}kg CO2 saved.';
  }

  // ── Send text message to Groq LLM ────────────────────────────────────────

  Future<String> sendMessage({
    required String userMessage,
    required ChatPersona persona,
    required List<ChatMessage> history,
  }) async {
    await Future.delayed(
        Duration(milliseconds: ChatbotConfig.requestDelayMs));

    String systemContent = _systemPrompt(persona);
    if (persona == ChatPersona.customer) {
      final liveContext = await _fetchCustomerShoeContext();
      if (liveContext != null) {
        systemContent = '$systemContent\n\n$liveContext';
      }
    }

    final messages = [
      {'role': 'system', 'content': systemContent},
      ...history.map((m) => {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.text,
          }),
      {'role': 'user', 'content': userMessage},
    ];

    final response = await http.post(
      Uri.parse('${ChatbotConfig.groqBaseUrl}/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${ChatbotConfig.groqApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model':       ChatbotConfig.llmModel,
        'messages':    messages,
        'max_tokens':  400,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else {
      throw Exception('Groq API error: ${response.statusCode}');
    }
  }

  // ── Speak response via flutter_tts ────────────────────────────────────────

  Future<void> speak(String text) async {
    if (_isSpeaking) await _tts.stop();
    _isSpeaking = true;
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    _isSpeaking = false;
    await _tts.stop();
  }

  void dispose() {
    _tts.stop();
  }
}
