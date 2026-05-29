import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  // ── Identity ──────────────────────────────────────────────────────────────
  final String cuid;     // CUID    — Customer Unique ID (also the document ID)
  final String cstNm;    // CST-NM  — Customer full name
  final String cstEml;   // CST-EML — Customer email address

  // ── Rewards ───────────────────────────────────────────────────────────────
  final int rwdNcb;      // RWD-NCB — NikeCoin balance

  // ── Linked Data ───────────────────────────────────────────────────────────
  final List<dynamic> suidLnk;  // SUID-LNK — Array of linked shoe IDs
  final List<dynamic> lcsRtn;   // LCS-RTN  — Return history (array)

  // ── Account ───────────────────────────────────────────────────────────────
  final bool dgtWlt;     // DGT-WLT — Digital wallet enabled
  final String accTyp;   // ACC-TYP — Account type (e.g. MEMBER)

  CustomerModel({
    required this.cuid,
    required this.cstNm,
    required this.cstEml,
    required this.rwdNcb,
    required this.suidLnk,
    required this.lcsRtn,
    required this.dgtWlt,
    required this.accTyp,
  });

  // ── Factory: build from a Firestore document snapshot ────────────────────
  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomerModel(
      cuid:    data['CUID']     as String? ?? '',
      cstNm:   data['CST-NM']   as String? ?? '',
      cstEml:  data['CST-EML']  as String? ?? '',
      rwdNcb:  (data['RWD-NCB'] as num?)?.toInt() ?? 0,
      suidLnk: data['SUID-LNK'] as List<dynamic>? ?? [],
      lcsRtn:  data['LCS-RTN']  as List<dynamic>? ?? [],
      dgtWlt:  data['DGT-WLT']  as bool? ?? false,
      accTyp:  data['ACC-TYP']  as String? ?? '',
    );
  }

  // ── Serialise back to a Map ───────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'CUID':     cuid,
      'CST-NM':   cstNm,
      'CST-EML':  cstEml,
      'RWD-NCB':  rwdNcb,
      'SUID-LNK': suidLnk,
      'LCS-RTN':  lcsRtn,
      'DGT-WLT':  dgtWlt,
      'ACC-TYP':  accTyp,
    };
  }

  // ── Convenience helpers ───────────────────────────────────────────────────

  /// First name only — used for greeting text in the UI.
  String get firstName => cstNm.split(' ').first;

  /// True when the customer has at least one linked shoe.
  bool get hasLinkedShoes => suidLnk.isNotEmpty;

  /// Number of shoes linked to this customer.
  int get linkedShoeCount => suidLnk.length;

  @override
  String toString() =>
      'CustomerModel(cuid: $cuid, cstNm: $cstNm, rwdNcb: $rwdNcb)';
}
