// ─────────────────────────────────────────────────────────────────────────────
// Region classification shared by the HQ Admin Dashboard.
//
// Hub docs only store a country name (HUB-CTR), never a region — this maps
// that country to the dashboard's GLOBAL/EUROPE/NORTH AMERICA filter. Only
// covers countries that could plausibly host a Nike ReRun hub; extend the
// two sets below as new hub countries get added.
//
// Routing decisions (RTE-DCN) come from RoutingAlgorithm — 'To resale.' and
// 'To cleaning.' both mean the shoe was resold as-is, not broken down into
// material, so neither counts toward "recycled". The other three outcomes
// are genuine Nike Grind material-recovery streams.
// ─────────────────────────────────────────────────────────────────────────────

const Set<String> _europeCountries = {
  'Germany', 'France', 'United Kingdom', 'Spain', 'Italy', 'Netherlands',
  'Belgium', 'Poland', 'Portugal', 'Sweden', 'Norway', 'Denmark', 'Finland',
  'Ireland', 'Austria', 'Switzerland',
};

const Set<String> _northAmericaCountries = {
  'United States', 'USA', 'Canada', 'Mexico',
};

const Set<String> _resaleDecisions = {'To resale.', 'To cleaning.'};

enum DashboardRegion { europe, northAmerica, other }

DashboardRegion regionForCountry(String country) {
  if (_europeCountries.contains(country)) return DashboardRegion.europe;
  if (_northAmericaCountries.contains(country)) return DashboardRegion.northAmerica;
  return DashboardRegion.other;
}

/// True when a routing decision means the shoe was recycled into raw
/// material (Nike Grind), rather than resold/refurbished as-is.
bool isRecycledDecision(String routingInstruction) =>
    routingInstruction.isNotEmpty && !_resaleDecisions.contains(routingInstruction);

/// True when a routing decision means the shoe was resold/refurbished
/// as-is, rather than broken down into material.
bool isResaleDecision(String routingInstruction) =>
    _resaleDecisions.contains(routingInstruction);
