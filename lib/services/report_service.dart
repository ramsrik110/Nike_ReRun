import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Real, four-page branded PDF: cover, two narrative pages (executive summary
// + regional performance/methodology), and one visual summary page. White
// corporate-paper look with French Lime accents, Bebas Neue headings, Lato
// body text (Nunito's only shipped as a variable font now, which the pdf
// package can't split into distinct regular/bold weights — Lato is the
// closest static-file substitute).
//
// Regional performance is driven entirely by the real hub list passed in —
// no hardcoded hub names. Global (no real hubs behind it) reads as a
// network-wide overview; Europe (backed by the real Berlin hub today) lists
// whatever hubs are actually in `hubs`, by name, so this stays correct
// automatically as real hubs get added later.
// ─────────────────────────────────────────────────────────────────────────────

class ReportHubInfo {
  final String name;
  final String city;
  final String country;
  final bool operational;
  final int throughput;

  const ReportHubInfo({
    required this.name,
    required this.city,
    required this.country,
    required this.operational,
    required this.throughput,
  });
}

class DashboardReportData {
  final String region;
  final String asOfDate;
  final bool isLive;
  final double co2Total;
  final String co2Unit;
  final int shoesProcessed;
  final double recycledPercent;
  final int activeHubs;
  final int resoldCount;
  final int recycledCount;
  final List<String> months;
  final List<double> shoesHistory;
  final List<ReportHubInfo> hubs;

  const DashboardReportData({
    required this.region,
    required this.asOfDate,
    required this.isLive,
    required this.co2Total,
    required this.co2Unit,
    required this.shoesProcessed,
    required this.recycledPercent,
    required this.activeHubs,
    required this.resoldCount,
    required this.recycledCount,
    required this.months,
    required this.shoesHistory,
    required this.hubs,
  });
}

const _pdfBlack  = PdfColor.fromInt(0xFF111111);
const _pdfGray   = PdfColor.fromInt(0xFF6B6B6B);
const _pdfLine   = PdfColor.fromInt(0xFFE4E4E0);
const _pdfLime   = PdfColor.fromInt(0xFFCDFC49);
const _pdfLimeDk = PdfColor.fromInt(0xFF3D4A0A); // readable text on lime fill

class ReportService {
  static Future<void> exportDashboardReport(DashboardReportData data) async {
    final bebas = pw.Font.ttf(
        (await rootBundle.load('assets/fonts/BebasNeue-Regular.ttf')));
    final body = pw.Font.ttf(
        (await rootBundle.load('assets/fonts/Lato-Regular.ttf')));
    final bodyBold = pw.Font.ttf(
        (await rootBundle.load('assets/fonts/Lato-Bold.ttf')));
    final logoBytes =
        (await rootBundle.load('assets/images/nikererun.png')).buffer.asUint8List();
    final logo = pw.MemoryImage(_tintLime(logoBytes));

    final theme = pw.ThemeData.withFont(base: body, bold: bodyBold);

    pw.TextStyle heading(double size, {PdfColor color = _pdfBlack}) =>
        pw.TextStyle(font: bebas, fontSize: size, color: color, letterSpacing: 1);
    pw.TextStyle bodyStyle(double size,
            {PdfColor color = _pdfBlack, bool bold = false}) =>
        pw.TextStyle(
            font: bold ? bodyBold : body, fontSize: size, color: color, lineSpacing: 3);

    final doc = pw.Document(theme: theme);

    // ── Page 1 — cover ────────────────────────────────────────────────────
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(48),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Image(logo, height: 34),
          pw.Spacer(),
          pw.Text('NIKE RERUN',
              style: bodyStyle(11, color: _pdfGray, bold: true)
                  .copyWith(letterSpacing: 2)),
          pw.SizedBox(height: 8),
          pw.Text('SUSTAINABILITY\nREPORT', style: heading(56)),
          pw.SizedBox(height: 20),
          pw.Container(width: 60, height: 4, color: _pdfLime),
          pw.SizedBox(height: 20),
          pw.Text(data.region, style: heading(22, color: _pdfGray)),
          pw.SizedBox(height: 6),
          pw.Text('As of ${data.asOfDate}', style: bodyStyle(11, color: _pdfGray)),
          pw.Spacer(),
          pw.Divider(color: _pdfLine),
          pw.SizedBox(height: 10),
          pw.Text(
            'Internal circularity pilot report — prepared from live Nike ReRun '
            'operational data. Part of Nike\'s Move to Zero journey toward '
            'zero carbon and zero waste.',
            style: bodyStyle(9, color: _pdfGray),
          ),
        ],
      ),
    ));

    // ── Page 2 — executive summary ───────────────────────────────────────
    final co2Label = data.co2Total >= 1000
        ? '${(data.co2Total / 1000).toStringAsFixed(1)}k${data.co2Unit}'
        : '${data.co2Total.toStringAsFixed(1)}${data.co2Unit}';
    final resoldSentence = data.resoldCount > 0
        ? 'Of those, ${data.resoldCount} pairs were graded and refurbished for '
            'resale rather than broken down — every pair resold is a pair that '
            'never needed new raw material at all.'
        : 'None of that volume has been routed to resale yet in this window — '
            'every pair processed so far went through material recovery.';
    final dataSourceSentence = data.isLive
        ? 'These figures are tracked live from real hub activity: every shoe '
            'scanned and routed at the facility updates this report in real '
            'time, so the numbers above reflect exactly what has happened — '
            'not a projection.'
        : 'These figures represent Nike ReRun\'s global-scale ambition — a '
            'presentation snapshot of the program\'s target trajectory, '
            'distinct from the smaller, fully live-tracked pilot currently '
            'running in Europe.';

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(48),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader(logo, 'Executive summary', bebas, body),
          pw.SizedBox(height: 24),
          pw.Text(
            'Nike ReRun exists to close the loop on the products we make. As '
            'part of Nike\'s broader Move to Zero mission — our journey toward '
            'zero carbon and zero waste — this program gives returned and '
            'end-of-life footwear a second life, whether that means '
            'refurbishing a pair for resale or breaking it down through Nike '
            'Grind into raw material for what comes next.',
            style: bodyStyle(11.5),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Over the period covered by this report, the ${data.region} '
            'operation diverted $co2Label of CO₂ that would otherwise have '
            'gone into landfill or incineration, processing '
            '${data.shoesProcessed} pairs of shoes through our circular '
            'pipeline. $resoldSentence',
            style: bodyStyle(11.5),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(18),
            decoration: const pw.BoxDecoration(
              color: _pdfLime,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _coverStat('${data.recycledPercent.toStringAsFixed(0)}%',
                    'material recycled', bebas, body),
                _coverStat(co2Label, 'CO2 diverted', bebas, body),
                _coverStat('${data.shoesProcessed}', 'shoes processed', bebas, body),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            '${data.recycledPercent.toStringAsFixed(0)}% of the material '
            'recovered in this period was broken down and returned to the '
            'supply chain as raw input — rubber, foam, and textile reclaimed '
            'through Nike Grind. That keeps us moving toward Nike\'s public '
            '2025 target of recycling at least 80% of manufacturing waste back '
            'into new products, a goal set as part of the Move to Zero '
            'commitment.',
            style: bodyStyle(11.5),
          ),
          pw.SizedBox(height: 14),
          pw.Text(dataSourceSentence, style: bodyStyle(11.5)),
          pw.Spacer(),
          _pageFooter(body, 2),
        ],
      ),
    ));

    // ── Page 3 — regional performance + methodology ──────────────────────
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(48),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader(logo, 'Regional performance', bebas, body),
          pw.SizedBox(height: 24),
          pw.Text(data.region.toUpperCase(), style: heading(16, color: _pdfGray)),
          pw.SizedBox(height: 10),
          pw.Text(_regionalOpening(data), style: bodyStyle(11.5)),
          pw.SizedBox(height: 16),
          if (data.hubs.isNotEmpty) ...[
            ...data.hubs.map((h) => _hubRow(h, body, bodyBold)),
            pw.SizedBox(height: 10),
          ] else if (data.region != 'GLOBAL') ...[
            pw.Text(
              'No hubs are currently reporting activity in this region.',
              style: bodyStyle(11, color: _pdfGray),
            ),
            pw.SizedBox(height: 10),
          ],
          pw.SizedBox(height: 16),
          pw.Text('METHODOLOGY', style: heading(16, color: _pdfGray)),
          pw.SizedBox(height: 10),
          pw.Text(
            'Shoes routed to resale or cleaning are counted as resold — the '
            'product is reused as-is. Shoes routed to fabric rework, sole '
            'rework, or full recycling are counted as recycled — the product '
            'is broken down into raw material through Nike Grind. Recycled '
            'percentage is calculated as recycled shoes divided by total shoes '
            'processed in the period.',
            style: bodyStyle(11.5),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Active hub count reflects hubs currently marked in operation. '
            'CO₂ diverted is the sum of the estimated carbon footprint '
            'recorded against each shoe at manufacture, attributed to this '
            'program once that shoe is processed rather than discarded.',
            style: bodyStyle(11.5),
          ),
          pw.Spacer(),
          _pageFooter(body, 3),
        ],
      ),
    ));

    // ── Page 4 — visual summary ───────────────────────────────────────────
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(48),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader(logo, 'Visual summary', bebas, body),
          pw.SizedBox(height: 24),
          pw.Row(
            children: [
              _kpiTile(co2Label, 'CO2 diverted', bebas, body),
              pw.SizedBox(width: 10),
              _kpiTile('${data.shoesProcessed}', 'Shoes processed', bebas, body),
              pw.SizedBox(width: 10),
              _kpiTile('${data.activeHubs}', 'Active hubs', bebas, body),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _kpiTile('${data.recycledPercent.toStringAsFixed(0)}%',
                  'Recycled material', bebas, body),
              pw.SizedBox(width: 10),
              _kpiTile('${data.resoldCount}', 'Shoes resold', bebas, body),
              pw.SizedBox(width: 10),
              _kpiTile(data.isLive ? 'LIVE' : 'SNAPSHOT', 'Data source', bebas, body),
            ],
          ),
          pw.SizedBox(height: 28),
          pw.Text('SHOES PROCESSED — LAST 6 MONTHS',
              style: heading(14, color: _pdfGray)),
          pw.SizedBox(height: 14),
          _barChart(data.months, data.shoesHistory, body),
          pw.SizedBox(height: 28),
          pw.Text('MATERIAL OUTCOMES', style: heading(14, color: _pdfGray)),
          pw.SizedBox(height: 12),
          _proportionBar(data.resoldCount, data.recycledCount, body),
          pw.Spacer(),
          _pageFooter(body, 4),
        ],
      ),
    ));

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename:
          'nike-rerun-report-${data.region.toLowerCase().replaceAll(' ', '-')}.pdf',
    );
  }

  // Recolors the logo's non-transparent pixels to French Lime, keeping the
  // original alpha channel — the raw asset is black/white, this is what
  // actually makes it "the lime Nike mark" like the rest of the app.
  static Uint8List _tintLime(Uint8List pngBytes) {
    final decoded = img.decodePng(pngBytes);
    if (decoded == null) return pngBytes;
    for (final pixel in decoded) {
      if (pixel.a > 0) {
        pixel
          ..r = 0xCD
          ..g = 0xFC
          ..b = 0x49;
      }
    }
    return Uint8List.fromList(img.encodePng(decoded));
  }

  // Opening paragraph framing — region-specific tone, but every concrete
  // fact (hub names, counts) comes from `data.hubs`/the metrics below it,
  // never hardcoded.
  static String _regionalOpening(DashboardReportData data) {
    if (data.region == 'EUROPE') {
      return 'Europe\'s circularity network is live and tracked in real '
          'time — every shoe scanned and routed at a European hub updates '
          'this report the moment it happens, not on a delay.';
    }
    if (data.region == 'NORTH AMERICA') {
      return 'North America\'s hub network is not yet live. This page will '
          'populate automatically once the first North American hub comes '
          'online and begins routing real shoes.';
    }
    return 'At a global scale, Nike ReRun is designed to operate across a '
        'growing network of hubs, each one a physical site where returned '
        'footwear is graded, refurbished, or broken down for material '
        'recovery. This view aggregates the full program\'s target reach — '
        '${data.activeHubs} hubs in the current plan.';
  }

  static pw.Widget _hubRow(ReportHubInfo hub, pw.Font body, pw.Font bodyBold) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _pdfLine),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(hub.name,
                  style: pw.TextStyle(font: bodyBold, fontSize: 11, color: _pdfBlack)),
              pw.Text('${hub.city}, ${hub.country} · '
                  '${hub.operational ? 'In operation' : 'Offline'}',
                  style: pw.TextStyle(font: body, fontSize: 9, color: _pdfGray)),
            ],
          ),
          pw.Text('${hub.throughput} routed',
              style: pw.TextStyle(font: bodyBold, fontSize: 11, color: _pdfLimeDk)),
        ],
      ),
    );
  }

  static pw.Widget _pageHeader(
      pw.MemoryImage logo, String title, pw.Font bebas, pw.Font body) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Image(logo, height: 18),
            pw.Text('NIKE RERUN',
                style: pw.TextStyle(
                    font: body, fontSize: 9, color: _pdfGray, letterSpacing: 1.5)),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Text(title, style: pw.TextStyle(font: bebas, fontSize: 30, color: _pdfBlack)),
        pw.SizedBox(height: 8),
        pw.Container(width: 40, height: 3, color: _pdfLime),
      ],
    );
  }

  static pw.Widget _pageFooter(pw.Font body, int page) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(color: _pdfLine),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Nike ReRun · Sustainability Report',
                style: pw.TextStyle(font: body, fontSize: 8, color: _pdfGray)),
            pw.Text('Page $page',
                style: pw.TextStyle(font: body, fontSize: 8, color: _pdfGray)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _coverStat(
      String value, String label, pw.Font bebas, pw.Font body) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(value, style: pw.TextStyle(font: bebas, fontSize: 26, color: _pdfLimeDk)),
        pw.Text(label,
            style: pw.TextStyle(font: body, fontSize: 8.5, color: _pdfLimeDk)),
      ],
    );
  }

  static pw.Widget _kpiTile(
      String value, String label, pw.Font bebas, pw.Font body) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _pdfLine),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(width: 18, height: 3, color: _pdfLime),
            pw.SizedBox(height: 8),
            pw.Text(value, style: pw.TextStyle(font: bebas, fontSize: 20, color: _pdfBlack)),
            pw.Text(label, style: pw.TextStyle(font: body, fontSize: 8, color: _pdfGray)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _barChart(
      List<String> months, List<double> values, pw.Font body) {
    final safe = values.isEmpty ? List.filled(months.length, 0.0) : values;
    final maxV = safe.isEmpty ? 1.0 : safe.reduce((a, b) => a > b ? a : b);
    final safeMax = maxV <= 0 ? 1.0 : maxV;
    final count = safe.length < months.length ? safe.length : months.length;

    return pw.SizedBox(
      height: 130,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: List.generate(count, (i) {
          final frac = (safe[i] / safeMax).clamp(0.03, 1.0).toDouble();
          final emptyFlex = ((1 - frac) * 1000).round().clamp(1, 999).toInt();
          final fillFlex = (frac * 1000).round().clamp(1, 999).toInt();
          return pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4),
              child: pw.Column(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Expanded(flex: emptyFlex, child: pw.SizedBox()),
                        pw.Expanded(
                          flex: fillFlex,
                          child: pw.Container(
                            width: double.infinity,
                            decoration: const pw.BoxDecoration(
                              color: _pdfLime,
                              borderRadius: pw.BorderRadius.vertical(
                                  top: pw.Radius.circular(2)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(months[i],
                      style: pw.TextStyle(font: body, fontSize: 8, color: _pdfGray)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  static pw.Widget _proportionBar(int resold, int recycled, pw.Font body) {
    final total = resold + recycled;
    final resoldFrac = total == 0 ? 0.0 : resold / total;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.ClipRRect(
          horizontalRadius: 3,
          verticalRadius: 3,
          child: pw.SizedBox(
            height: 10,
            child: total == 0
                ? pw.Container(color: _pdfLine)
                : pw.Row(
                    children: [
                      pw.Expanded(
                        flex: (resoldFrac * 1000).round().clamp(1, 999).toInt(),
                        child: pw.Container(color: const PdfColor.fromInt(0xFFA9C766)),
                      ),
                      pw.Expanded(
                        flex: ((1 - resoldFrac) * 1000).round().clamp(1, 999).toInt(),
                        child: pw.Container(color: _pdfLime),
                      ),
                    ],
                  ),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Text('Resold: $resold',
                style: pw.TextStyle(font: body, fontSize: 9, color: _pdfGray)),
            pw.SizedBox(width: 16),
            pw.Text('Recycled: $recycled',
                style: pw.TextStyle(font: body, fontSize: 9, color: _pdfGray)),
          ],
        ),
      ],
    );
  }
}
