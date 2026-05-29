import '../models/shoe_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Input enums
// ─────────────────────────────────────────────────────────────────────────────

enum SoleCondition { intact, damaged }
enum FabricCondition { intact, damaged }
enum WearLevel { light, moderate, heavy }
enum StructuralIntegrity { intact, minorDamage, majorDamage }
enum EstimatedAge { underOneYear, oneToTwo, twoToThree, overThree }

// String → enum helpers (map from pill/dropdown label text)
extension SoleConditionX on String {
  SoleCondition toSoleCondition() =>
      toLowerCase() == 'done.' ? SoleCondition.damaged : SoleCondition.intact;
  FabricCondition toFabricCondition() =>
      toLowerCase() == 'done.' ? FabricCondition.damaged : FabricCondition.intact;
  WearLevel toWearLevel() {
    switch (toLowerCase()) {
      case 'moderate': return WearLevel.moderate;
      case 'heavy':    return WearLevel.heavy;
      default:         return WearLevel.light;
    }
  }
  StructuralIntegrity toStructuralIntegrity() {
    switch (toLowerCase()) {
      case 'minor damage': return StructuralIntegrity.minorDamage;
      case 'major damage': return StructuralIntegrity.majorDamage;
      default:             return StructuralIntegrity.intact;
    }
  }
  EstimatedAge toEstimatedAge() {
    switch (this) {
      case 'Under 1 Year': return EstimatedAge.underOneYear;
      case '1–2 Years':    return EstimatedAge.oneToTwo;
      case '2–3 Years':    return EstimatedAge.twoToThree;
      default:             return EstimatedAge.overThree;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result model
// ─────────────────────────────────────────────────────────────────────────────

class RoutingResult {
  final String decision;          // Short ALL CAPS Nike headline — stored in RTE-DCN
  final String routeName;         // Full route name
  final String whatNext;          // Description of next processing step
  final String conditionGrade;    // Shoe Grade label
  final String materialMatch;     // Material driving sub-stream
  final int    nikeCoinReward;    // Reward based on age
  final String wearLevelLabel;    // Human-readable wear level
  final String structuralLabel;   // Human-readable structural integrity
  final String estimatedAgeLabel; // Human-readable age
  final bool   cleaningRequired;  // Whether cleaning is needed

  const RoutingResult({
    required this.decision,
    required this.routeName,
    required this.whatNext,
    required this.conditionGrade,
    required this.materialMatch,
    required this.nikeCoinReward,
    required this.wearLevelLabel,
    required this.structuralLabel,
    required this.estimatedAgeLabel,
    required this.cleaningRequired,
  });

  @override
  String toString() => 'RoutingResult(decision: $decision)';
}

// ─────────────────────────────────────────────────────────────────────────────
// The algorithm
// ─────────────────────────────────────────────────────────────────────────────

class RoutingAlgorithm {
  /// Run the full routing algorithm with all six grading inputs.
  static RoutingResult run({
    required ShoeModel          shoe,
    required SoleCondition      soleCondition,
    required FabricCondition    fabricCondition,
    required WearLevel          wearLevel,
    required StructuralIntegrity structuralIntegrity,
    required EstimatedAge       estimatedAge,
    required bool               cleaningRequired,
  }) {
    // ── Step 1: Primary routing from 2×2 condition matrix ─────────────────
    final bool soleOk   = soleCondition   == SoleCondition.intact;
    final bool fabricOk = fabricCondition == FabricCondition.intact;

    String decision;
    String routeName;

    if (soleOk && fabricOk) {
      decision  = 'FRESH START.';
      routeName = 'Refurbish for Resale';
    } else if (!soleOk && fabricOk) {
      decision  = 'BACK TO FABRIC.';
      routeName = 'Flyknit Textile Re-Weaving';
    } else if (soleOk && !fabricOk) {
      decision  = 'BACK TO RUBBER.';
      routeName = 'Nike Grind Rubber Shredding';
    } else {
      decision  = 'FULL BREAK DOWN.';
      routeName = 'Thermoplastic Pelletizing';
    }

    // Override to full breakdown if structural integrity is majorDamage
    if (structuralIntegrity == StructuralIntegrity.majorDamage) {
      decision  = 'FULL BREAK DOWN.';
      routeName = 'Thermoplastic Pelletizing';
    }

    // ── Step 2: Condition grade ────────────────────────────────────────────
    final String conditionGrade = _grade(soleOk, fabricOk, wearLevel, structuralIntegrity);

    // ── Step 3: Material match ─────────────────────────────────────────────
    final String materialMatch = _materialMatch(shoe, soleOk, fabricOk);

    // ── Step 4: What's next ────────────────────────────────────────────────
    final String whatNext = _whatNext(routeName, cleaningRequired);

    // ── Step 5: NikeCoin reward based on age ──────────────────────────────
    final int nikeCoinReward = _coinReward(estimatedAge);

    // ── Step 6: Human-readable labels ─────────────────────────────────────
    final String wearLevelLabel      = _wearLabel(wearLevel);
    final String structuralLabel     = _structuralLabel(structuralIntegrity);
    final String estimatedAgeLabel   = _ageLabel(estimatedAge);

    return RoutingResult(
      decision:          decision,
      routeName:         routeName,
      whatNext:          whatNext,
      conditionGrade:    conditionGrade,
      materialMatch:     materialMatch,
      nikeCoinReward:    nikeCoinReward,
      wearLevelLabel:    wearLevelLabel,
      structuralLabel:   structuralLabel,
      estimatedAgeLabel: estimatedAgeLabel,
      cleaningRequired:  cleaningRequired,
    );
  }

  // ── Condition grade ───────────────────────────────────────────────────────
  static String _grade(bool soleOk, bool fabricOk, WearLevel wear,
      StructuralIntegrity integrity) {
    if (integrity == StructuralIntegrity.majorDamage) return 'Grade D — Severe';
    if (soleOk && fabricOk && wear == WearLevel.light) return 'Grade A — Resaleable';
    if (soleOk && fabricOk) return 'Grade B — Good Condition';
    if (!soleOk && fabricOk)  return 'Grade B — Fabric Intact';
    if (soleOk && !fabricOk)  return 'Grade B — Sole Intact';
    return 'Grade C — Full Breakdown';
  }

  // ── Material match ────────────────────────────────────────────────────────
  static String _materialMatch(ShoeModel shoe, bool soleOk, bool fabricOk) {
    if (soleOk && fabricOk) {
      if (shoe.mcpLth > 0) return 'Leather ${shoe.mcpLth.toInt()}% — Premium Clean';
      if (shoe.mcpFlk > 0) return 'Flyknit ${shoe.mcpFlk.toInt()}% — Textile Clean';
      return 'Multi-material — Standard Clean';
    }
    if (!soleOk && fabricOk) {
      if (shoe.mcpFlk >= 40) return 'Flyknit ${shoe.mcpFlk.toInt()}% — High-Yield Weave';
      if (shoe.mcpFlk > 0)   return 'Flyknit ${shoe.mcpFlk.toInt()}% — Blended Weave';
      return 'Synthetic Textile — Standard Weave';
    }
    if (soleOk && !fabricOk) {
      if (shoe.mcpRbr >= 30) return 'Rubber ${shoe.mcpRbr.toInt()}% — High-Density Grind';
      return 'Rubber ${shoe.mcpRbr.toInt()}% — Standard Grind';
    }
    if (shoe.mcpFom >= 40) return 'Foam ${shoe.mcpFom.toInt()}% — High-Foam Pelletize';
    if (shoe.mcpRbr >= 30) return 'Rubber ${shoe.mcpRbr.toInt()}% — Rubber Pelletize';
    return 'Multi-material — Blended Pelletize';
  }

  // ── What's next ───────────────────────────────────────────────────────────
  static String _whatNext(String routeName, bool cleaning) {
    final suffix = cleaning ? ' Cleaning required first.' : '';
    switch (routeName) {
      case 'Refurbish for Resale':
        return 'Inspect and list on Nike Refurbished.$suffix';
      case 'Flyknit Textile Re-Weaving':
        return 'Upper yarn extracted for new Flyknit fabric.$suffix';
      case 'Nike Grind Rubber Shredding':
        return 'Sole shredded into Nike Grind for sports surfaces.$suffix';
      default:
        return 'Full breakdown into thermoplastic pellets.$suffix';
    }
  }

  // ── NikeCoin reward by age ────────────────────────────────────────────────
  static int _coinReward(EstimatedAge age) {
    switch (age) {
      case EstimatedAge.underOneYear: return 150;
      case EstimatedAge.oneToTwo:     return 120;
      case EstimatedAge.twoToThree:   return 80;
      case EstimatedAge.overThree:    return 50;
    }
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

  static String _ageLabel(EstimatedAge a) {
    switch (a) {
      case EstimatedAge.underOneYear: return 'Under 1 Year';
      case EstimatedAge.oneToTwo:     return '1–2 Years';
      case EstimatedAge.twoToThree:   return '2–3 Years';
      case EstimatedAge.overThree:    return 'Over 3 Years';
    }
  }
}
