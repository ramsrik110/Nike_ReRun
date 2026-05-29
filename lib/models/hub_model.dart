import 'package:cloud_firestore/cloud_firestore.dart';

class HubModel {
  // ── Identity ──────────────────────────────────────────────────────────────
  final String huid;     // HUID    — Hub Unique ID (also the document ID)
  final String hubNm;    // HUB-NM  — Hub name
  final String hubCty;   // HUB-CTY — City
  final String hubCtr;   // HUB-CTR — Country
  final String hubDsc;   // HUB-DSC — Hub description

  // ── Operations ────────────────────────────────────────────────────────────
  final int hubLns;      // HUB-LNS — Number of sorting lanes
  final int hubTsp;      // HUB-TSP — Throughput (shoes processed)
  final String hubSts;   // HUB-STS — Operational status string

  // ── Routing Log ───────────────────────────────────────────────────────────
  final List<dynamic> rteLog;  // RTE-LOG — Array of routing log entries

  HubModel({
    required this.huid,
    required this.hubNm,
    required this.hubCty,
    required this.hubCtr,
    required this.hubDsc,
    required this.hubLns,
    required this.hubTsp,
    required this.hubSts,
    required this.rteLog,
  });

  // ── Factory: build from a Firestore document snapshot ────────────────────
  factory HubModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HubModel(
      huid:   data['HUID']    as String? ?? '',
      hubNm:  data['HUB-NM']  as String? ?? '',
      hubCty: data['HUB-CTY'] as String? ?? '',
      hubCtr: data['HUB-CTR'] as String? ?? '',
      hubDsc: data['HUB-DSC'] as String? ?? '',
      hubLns: (data['HUB-LNS'] as num?)?.toInt() ?? 0,
      hubTsp: (data['HUB-TSP'] as num?)?.toInt() ?? 0,
      hubSts: data['HUB-STS'] as String? ?? '',
      rteLog: data['RTE-LOG'] as List<dynamic>? ?? [],
    );
  }

  // ── Serialise back to a Map ───────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'HUID':    huid,
      'HUB-NM':  hubNm,
      'HUB-CTY': hubCty,
      'HUB-CTR': hubCtr,
      'HUB-DSC': hubDsc,
      'HUB-LNS': hubLns,
      'HUB-TSP': hubTsp,
      'HUB-STS': hubSts,
      'RTE-LOG': rteLog,
    };
  }

  // ── Convenience helpers ───────────────────────────────────────────────────

  /// City and country combined — used on the result screen badge.
  String get locationLabel => '$hubCty, $hubCtr';

  /// True when the hub is currently in operation.
  bool get isOperational => hubSts.toUpperCase().contains('OPERATION');

  /// Number of routing events logged so far.
  int get routingEventCount => rteLog.length;

  @override
  String toString() =>
      'HubModel(huid: $huid, hubNm: $hubNm, hubSts: $hubSts)';
}
