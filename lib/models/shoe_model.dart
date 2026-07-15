import 'package:cloud_firestore/cloud_firestore.dart';

class ShoeModel {
  // ── Identity ──────────────────────────────────────────────────────────────
  final String suid;       // SUID  — Shoe Unique ID (also the document ID)
  final String snm;        // SNM   — Full shoe name
  final String snmHdl;     // SNM-HDL — ALL CAPS Nike headline
  final String snmDsc;     // SNM-DSC — One-line Nike description
  final String snmImg;     // SNM-IMG — Nike CDN image URL

  // ── Material Composition Percentages ─────────────────────────────────────
  final double mcpFlk;     // MCP-FLK — Flyknit %
  final double mcpRbr;     // MCP-RBR — Rubber %
  final double mcpFom;     // MCP-FOM — Foam %
  final double mcpLth;     // MCP-LTH — Leather %

  // ── Manufacturing ─────────────────────────────────────────────────────────
  final String mfgCtr;     // MFG-CTR — Manufacturing country
  final String mfgNrg;     // MFG-NRG — Energy source

  // ── Eco & Carbon ──────────────────────────────────────────────────────────
  final double ecoCo2;     // ECO-CO2 — Carbon saved in kg

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  final List<dynamic> lcsRpr;  // LCS-RPR — Repair history (array)
  final String lcsSts;         // LCS-STS — Lifecycle status
  final String rteDcn;         // RTE-DCN — Routing decision

  // ── Links & Transaction ───────────────────────────────────────────────────
  final String cuidLnk;    // CUID-LNK — Linked customer ID
  final String txnDtp;     // TXN-DTP  — Date of purchase
  final String txnRtn;     // TXN-RTN  — Date the customer returned it (set by
                            // the return flow; used to compute shoe age at
                            // inspection instead of manual entry)
  final int rwdAmt;        // RWD-AMT  — NikeCoin reward amount

  ShoeModel({
    required this.suid,
    required this.snm,
    required this.snmHdl,
    required this.snmDsc,
    required this.snmImg,
    required this.mcpFlk,
    required this.mcpRbr,
    required this.mcpFom,
    required this.mcpLth,
    required this.mfgCtr,
    required this.mfgNrg,
    required this.ecoCo2,
    required this.lcsRpr,
    required this.lcsSts,
    required this.rteDcn,
    required this.cuidLnk,
    required this.txnDtp,
    required this.txnRtn,
    required this.rwdAmt,
  });

  // ── Factory: build from a Firestore document snapshot ────────────────────
  factory ShoeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShoeModel(
      suid:    data['SUID']    as String? ?? '',
      snm:     data['SNM']     as String? ?? '',
      snmHdl:  data['SNM-HDL'] as String? ?? '',
      snmDsc:  data['SNM-DSC'] as String? ?? '',
      snmImg:  data['SNM-IMG'] as String? ?? '',
      mcpFlk:  (data['MCP-FLK'] as num?)?.toDouble() ?? 0.0,
      mcpRbr:  (data['MCP-RBR'] as num?)?.toDouble() ?? 0.0,
      mcpFom:  (data['MCP-FOM'] as num?)?.toDouble() ?? 0.0,
      mcpLth:  (data['MCP-LTH'] as num?)?.toDouble() ?? 0.0,
      mfgCtr:  data['MFG-CTR'] as String? ?? '',
      mfgNrg:  data['MFG-NRG'] as String? ?? '',
      ecoCo2:  (data['ECO-CO2'] as num?)?.toDouble() ?? 0.0,
      lcsRpr:  data['LCS-RPR'] as List<dynamic>? ?? [],
      lcsSts:  data['LCS-STS'] as String? ?? '',
      rteDcn:  data['RTE-DCN'] as String? ?? '',
      cuidLnk: data['CUID-LNK'] as String? ?? '',
      txnDtp:  data['TXN-DTP'] as String? ?? '',
      txnRtn:  data['TXN-RTN'] as String? ?? '',
      rwdAmt:  (data['RWD-AMT'] as num?)?.toInt() ?? 0,
    );
  }

  // ── Serialise back to a Map (useful for writes / updates) ─────────────────
  Map<String, dynamic> toMap() {
    return {
      'SUID':    suid,
      'SNM':     snm,
      'SNM-HDL': snmHdl,
      'SNM-DSC': snmDsc,
      'SNM-IMG': snmImg,
      'MCP-FLK': mcpFlk,
      'MCP-RBR': mcpRbr,
      'MCP-FOM': mcpFom,
      'MCP-LTH': mcpLth,
      'MFG-CTR': mfgCtr,
      'MFG-NRG': mfgNrg,
      'ECO-CO2': ecoCo2,
      'LCS-RPR': lcsRpr,
      'LCS-STS': lcsSts,
      'RTE-DCN': rteDcn,
      'CUID-LNK': cuidLnk,
      'TXN-DTP': txnDtp,
      'TXN-RTN': txnRtn,
      'RWD-AMT': rwdAmt,
    };
  }

  // ── Convenience helpers used by the UI ────────────────────────────────────

  /// Returns the dominant material name for display (highest % wins).
  String get dominantMaterial {
    final scores = {
      'Flyknit': mcpFlk,
      'Rubber':  mcpRbr,
      'Foam':    mcpFom,
      'Leather': mcpLth,
    };
    return scores.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  /// True when the shoe has a non-empty routing decision already set.
  bool get hasRoutingDecision => rteDcn.isNotEmpty;

  /// Returns only materials that have a percentage greater than zero.
  Map<String, double> get activeMaterials {
    final map = <String, double>{};
    if (mcpFlk > 0) map['Flyknit'] = mcpFlk;
    if (mcpRbr > 0) map['Rubber']  = mcpRbr;
    if (mcpFom > 0) map['Foam']    = mcpFom;
    if (mcpLth > 0) map['Leather'] = mcpLth;
    return map;
  }

  @override
  String toString() => 'ShoeModel(suid: $suid, snm: $snm, lcsSts: $lcsSts)';
}
