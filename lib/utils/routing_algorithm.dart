import '../models/shoe_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Input enums
// ─────────────────────────────────────────────────────────────────────────────

enum SoleCondition { fresh, worn, damaged }
enum FabricCondition { fresh, worn, damaged }
enum WearLevel { light, moderate, heavy }
enum StructuralIntegrity { intact, minorDamage, majorDamage }
enum EstimatedAge { underOneYear, oneToTwo, twoToThree, overThree }

// String → enum helpers (map from pill/dropdown label text)
extension SoleConditionX on String {
  SoleCondition toSoleCondition() {
    switch (this) {
      case 'Fresh':   return SoleCondition.fresh;
      case 'Worn':    return SoleCondition.worn;
      default:        return SoleCondition.damaged;
    }
  }
  FabricCondition toFabricCondition() {
    switch (this) {
      case 'Fresh':   return FabricCondition.fresh;
      case 'Worn':    return FabricCondition.worn;
      default:        return FabricCondition.damaged;
    }
  }
  WearLevel toWearLevel() {
    switch (this) {
      case 'Moderate': return WearLevel.moderate;
      case 'Heavy':    return WearLevel.heavy;
      default:         return WearLevel.light;
    }
  }
  StructuralIntegrity toStructuralIntegrity() {
    switch (this) {
      case 'Minor Damage': return StructuralIntegrity.minorDamage;
      case 'Major Damage': return StructuralIntegrity.majorDamage;
      default:             return StructuralIntegrity.intact;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result model
// ─────────────────────────────────────────────────────────────────────────────

class RoutingResult {
  final bool   resellable;          // drives the lime-vs-dark result screen wash
  final String routingInstruction;  // the big headline — "To sole rework." etc,
                                     // stored in RTE-DCN
  final String subLabel;            // small subtext: condition grade or Grind stream
  final String materialMatch;       // material driving the sub-stream
  final String wearLevelLabel;
  final String structuralLabel;
  final String soleLabel;
  final String fabricLabel;
  final String estimatedAgeLabel;
  final bool   cleaningRequired;

  const RoutingResult({
    required this.resellable,
    required this.routingInstruction,
    required this.subLabel,
    required this.materialMatch,
    required this.wearLevelLabel,
    required this.structuralLabel,
    required this.soleLabel,
    required this.fabricLabel,
    required this.estimatedAgeLabel,
    required this.cleaningRequired,
  });

  @override
  String toString() => 'RoutingResult(routingInstruction: $routingInstruction)';
}

// ─────────────────────────────────────────────────────────────────────────────
// The algorithm
//
// Gate: a shoe is resellable unless structural integrity is majorly damaged,
// or the sole or fabric is damaged beyond use. Everything else (Worn sole/
// fabric, Minor structural damage, heavier cosmetic wear) stays resellable
// but downgrades the grade and flags refurbishment first.
//
// Recycle stream is named after whichever material is still salvageable —
// e.g. sole damaged but fabric intact means the fabric gets recovered, so
// the shoe routes "To fabric rework."
// ─────────────────────────────────────────────────────────────────────────────

class RoutingAlgorithm {
  static RoutingResult run({
    required ShoeModel          shoe,
    required SoleCondition      soleCondition,
    required FabricCondition    fabricCondition,
    required WearLevel          wearLevel,
    required StructuralIntegrity structuralIntegrity,
    required bool               cleaningRequired,
  }) {
    final soleDamaged   = soleCondition   == SoleCondition.damaged;
    final fabricDamaged = fabricCondition == FabricCondition.damaged;
    final structuralMajor = structuralIntegrity == StructuralIntegrity.majorDamage;

    final resellable = !structuralMajor && !soleDamaged && !fabricDamaged;
    final estimatedAge = _computeAge(shoe);

    String routingInstruction;
    String subLabel;
    String materialMatch;

    if (resellable) {
      // Headline is always "To resale." here — grade is informational
      // context (subLabel), never a different main outcome. "Cleaning
      // Required" is surfaced separately as its own footnote in the UI
      // (see RoutingResult.cleaningRequired), it never changes this
      // headline on any outcome, resale or recycle.
      final grade = _grade(soleCondition, fabricCondition, wearLevel, structuralIntegrity);
      routingInstruction = 'To resale.';
      subLabel           = grade;
      materialMatch       = _materialMatchResale(shoe);
    } else {
      if (soleDamaged && !fabricDamaged) {
        routingInstruction = 'To fabric rework.';
        subLabel           = 'Nike Grind: Fiber';
        materialMatch       = _materialMatchFiber(shoe);
      } else if (fabricDamaged && !soleDamaged) {
        routingInstruction = 'To sole rework.';
        subLabel           = 'Nike Grind: Rubber';
        materialMatch       = _materialMatchRubber(shoe);
      } else {
        routingInstruction = 'To full recycle.';
        subLabel           = 'Nike Grind: Full breakdown';
        materialMatch       = _materialMatchBreakdown(shoe);
      }
    }

    return RoutingResult(
      resellable:          resellable,
      routingInstruction:  routingInstruction,
      subLabel:            subLabel,
      materialMatch:       materialMatch,
      wearLevelLabel:      _wearLabel(wearLevel),
      structuralLabel:     _structuralLabel(structuralIntegrity),
      soleLabel:           _conditionLabel(soleCondition.name),
      fabricLabel:         _conditionLabel(fabricCondition.name),
      estimatedAgeLabel:   _ageLabel(estimatedAge),
      // Always the inspector's raw input, shown as its own note regardless
      // of outcome — not folded into the resale-grade "needs refurb" logic.
      cleaningRequired:    cleaningRequired,
    );
  }

  // ── Age — computed from purchase (TXN-DTP) to return (TXN-RTN) dates on
  // the shoe record, never manually entered by the inspector. Falls back to
  // "now" as the return point when TXN-RTN isn't set (e.g. seed/demo shoes
  // that were never run through a real customer return).
  static EstimatedAge _computeAge(ShoeModel shoe) {
    final purchased = _parseDate(shoe.txnDtp);
    if (purchased == null) return EstimatedAge.overThree;
    final returned = _parseDate(shoe.txnRtn) ?? DateTime.now();
    final months = returned.difference(purchased).inDays / 30.44;
    if (months < 12) return EstimatedAge.underOneYear;
    if (months < 24) return EstimatedAge.oneToTwo;
    if (months < 36) return EstimatedAge.twoToThree;
    return EstimatedAge.overThree;
  }

  /// Parses the app's stored date strings, format "MM/DD/YYYY".
  static DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;
    final parts = value.split('/');
    if (parts.length != 3) return null;
    final month = int.tryParse(parts[0]);
    final day   = int.tryParse(parts[1]);
    final year  = int.tryParse(parts[2]);
    if (month == null || day == null || year == null) return null;
    return DateTime(year, month, day);
  }

  // ── Grade (resale path only) ────────────────────────────────────────────
  static String _grade(SoleCondition sole, FabricCondition fabric,
      WearLevel wear, StructuralIntegrity structural) {
    if (wear == WearLevel.heavy) return 'Cosmetically Flawed';
    if (sole == SoleCondition.worn ||
        fabric == FabricCondition.worn ||
        wear == WearLevel.moderate ||
        structural == StructuralIntegrity.minorDamage) {
      return 'Gently Worn';
    }
    return 'Like New';
  }

  // ── Material match ────────────────────────────────────────────────────────
  static String _materialMatchResale(ShoeModel shoe) {
    if (shoe.mcpLth > 0) return 'Leather ${shoe.mcpLth.toInt()}% — premium clean';
    if (shoe.mcpFlk > 0) return 'Flyknit ${shoe.mcpFlk.toInt()}% — textile clean';
    return 'Multi-material — standard clean';
  }

  static String _materialMatchFiber(ShoeModel shoe) {
    if (shoe.mcpFlk >= 40) return 'Flyknit ${shoe.mcpFlk.toInt()}% — high-yield weave';
    if (shoe.mcpFlk > 0)   return 'Flyknit ${shoe.mcpFlk.toInt()}% — blended weave';
    return 'Synthetic textile — standard weave';
  }

  static String _materialMatchRubber(ShoeModel shoe) {
    if (shoe.mcpRbr >= 30) return 'Rubber ${shoe.mcpRbr.toInt()}% — high-density grind';
    return 'Rubber ${shoe.mcpRbr.toInt()}% — standard grind';
  }

  static String _materialMatchBreakdown(ShoeModel shoe) {
    if (shoe.mcpFom >= 40) return 'Foam ${shoe.mcpFom.toInt()}% — high-foam pelletize';
    if (shoe.mcpRbr >= 30) return 'Rubber ${shoe.mcpRbr.toInt()}% — rubber pelletize';
    return 'Multi-material — blended pelletize';
  }

  // ── Human-readable labels ─────────────────────────────────────────────────
  static String _wearLabel(WearLevel w) {
    switch (w) {
      case WearLevel.light:    return 'Light Wear';
      case WearLevel.moderate: return 'Moderate Wear';
      case WearLevel.heavy:    return 'Heavy Wear';
    }
  }

  static String _structuralLabel(StructuralIntegrity s) {
    switch (s) {
      case StructuralIntegrity.intact:      return 'Fully Intact';
      case StructuralIntegrity.minorDamage: return 'Minor Damage';
      case StructuralIntegrity.majorDamage: return 'Major Damage';
    }
  }

  static String _conditionLabel(String enumName) {
    switch (enumName) {
      case 'fresh':   return 'Fresh';
      case 'worn':    return 'Worn';
      default:        return 'Damaged';
    }
  }

  static String _ageLabel(EstimatedAge a) {
    switch (a) {
      case EstimatedAge.underOneYear: return 'Under 1 Year';
      case EstimatedAge.oneToTwo:     return '1–2 Years';
      case EstimatedAge.twoToThree:   return '2–3 Years';
      case EstimatedAge.overThree:    return 'Over 3 Years';
    }
  }
}
