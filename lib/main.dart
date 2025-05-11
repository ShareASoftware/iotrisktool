import 'package:flutter/material.dart';
// Import PDF generation packages
import 'package:flutter/services.dart'; // For Clipboard
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
// Import localization packages
import 'dart:ui' as ui; // For PlatformDispatcher
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Generated file

void main() {
  runApp(const MyApp());
}

// Change MyApp to StatefulWidget to manage locale
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();

  // Add this method to allow child widgets to change the locale
  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.changeLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en'); // Default locale, will be updated

  @override
  void initState() {
    super.initState();
    _setInitialLocale();
  }

  void _setInitialLocale() {
    final ui.Locale systemLocale = ui.PlatformDispatcher.instance.locale;
    _locale = AppLocalizations.supportedLocales.firstWhere(
        (sl) => sl.languageCode == systemLocale.languageCode,
        orElse: () => const Locale('en')); // Fallback to English
  }

  void changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ETSI EN 303 645 v3.1.3 (2024-09) Threat Assessment',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter', // Using Inter font
      ),
      // --- Localization Setup ---
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate, // Add this
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English, no country code
        Locale('it', ''), // Italian, no country code
      ],
      // --- End Localization Setup ---
      home: ThreatAssessmentPage(currentLocale: _locale), // Pass current locale
      debugShowCheckedModeBanner: false, // Hide debug banner
    );
  }
}

// Data model for a single threat row
class ThreatData {
  final String provisionName; // e.g., "Provision 5.1-1"
  final String provisionStatus; // e.g., "M F (a)"
  final String
      description; // Optional: Add detailed description if needed later
  String applicable;
  String likelihood;
  String impact;
  String notes;
  String status; // Added status field
  String riskScore;
  PdfColor riskColor; // Use PdfColor for PDF

  ThreatData({
    required this.provisionName,
    required this.provisionStatus,
    required this.description,
    this.applicable = 'na',
    this.likelihood = 'na',
    this.impact = 'na',
    this.notes = '',
    this.status = 'open', // Default status
    this.riskScore = 'N/A',
    this.riskColor = PdfColors.grey,
  });

  // Helper method to create a copy with updated values
  ThreatData copyWith({
    String? applicable,
    String? likelihood,
    String? impact,
    String? notes,
    String? status,
    String? riskScore,
    PdfColor? riskColor,
  }) {
    return ThreatData(
        provisionName: provisionName,
        provisionStatus: provisionStatus,
        description: description, // Keep original description
        applicable: applicable ?? this.applicable,
        likelihood: likelihood ?? this.likelihood,
        impact: impact ?? this.impact,
        notes: notes ?? this.notes,
        status: status ?? this.status,
        riskScore: riskScore ?? this.riskScore,
        riskColor: riskColor ?? this.riskColor);
  }
}

class ThreatAssessmentPage extends StatefulWidget {
  final Locale currentLocale; // Add locale parameter
  const ThreatAssessmentPage(
      {super.key, required this.currentLocale}); // Update constructor

  @override
  _ThreatAssessmentPageState createState() => _ThreatAssessmentPageState();
}

class _ThreatAssessmentPageState extends State<ThreatAssessmentPage> {
  // Controller and variable for Product Name
  final TextEditingController _productNameController = TextEditingController();
  String _productName = '';

  // State variables for loading
  List<dynamic> _threatDataList = []; // Initialize to empty
  bool _isLoading = true; // Start in loading state
  double _loadingProgress = 0.0;
  bool _threatDataInitialized =
      false; // Flag to ensure initialization happens once

  @override
  void initState() {
    super.initState();
    // Listen to changes in the product name field
    _productNameController.addListener(() {
      if (mounted) {
        setState(() {
          _productName = _productNameController.text;
        });
      }
    });
    // Trigger the first data load after the initial frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_threatDataInitialized) {
        _performDataLoading();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The initial load is now primarily handled by initState's postFrameCallback.
    // This method is kept for completeness. If, for some reason, initState's
    // callback didn't run or data isn't initialized, this could be a fallback.
    // However, with the current setup, initState should handle the first load.
  }

  @override
  void didUpdateWidget(ThreatAssessmentPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentLocale != oldWidget.currentLocale) {
      // Locale has changed, re-initialize the threat data list
      _performDataLoading(); // This will show the loading screen and reload data
    }
  }

  Future<void> _performDataLoading() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _loadingProgress = 0.0;
      // _threatDataList = []; // Optionally clear old data, or let it be replaced
    });

    // Ensure AppLocalizations is available
    final l10n = AppLocalizations.of(context)!;
    await _constructAndPopulateThreatDataList(l10n, (progress) {
      if (mounted) {
        setState(() {
          _loadingProgress = progress;
        });
      }
    });

    if (mounted) {
      setState(() {
        _isLoading = false;
        _threatDataInitialized = true; // Mark that a full load has completed
      });
    }
  }

  // This method replaces the old synchronous _initializeThreatDataList
  Future<void> _constructAndPopulateThreatDataList(
      AppLocalizations l10n, Function(double) onProgress) async {
    List<dynamic> newItems = [];

    // Define all items to be added, mirroring the structure of your old _initializeThreatDataList
    final List<dynamic> allItemsBlueprint = [
      // --- Section: 5.0 Reporting implementation ---
      l10n.section_5_0_title,
      ThreatData(
          provisionName: l10n.prov_5_0_1,
          provisionStatus: 'M',
          description: l10n.p_5_0_1_desc),

      // --- Subsection: 5.1 No universal default passwords ---
      l10n.section_5_1_title,
      ThreatData(
          provisionName: l10n.prov_5_1_1,
          provisionStatus: 'M F (a)',
          description: l10n.p_5_1_1_desc),
      ThreatData(
          provisionName: l10n.prov_5_1_2,
          provisionStatus: 'M F (b)',
          description: l10n.p_5_1_2_desc),
      ThreatData(
          provisionName: l10n.prov_5_1_2A,
          provisionStatus: 'R',
          description: l10n.p_5_1_2A_desc),
      ThreatData(
          provisionName: l10n.prov_5_1_3,
          provisionStatus: 'M F (c)',
          description: l10n.p_5_1_3_desc),
      ThreatData(
          provisionName: l10n.prov_5_1_4,
          provisionStatus: 'M F (d)',
          description: l10n.p_5_1_4_desc),
      ThreatData(
          provisionName: l10n.prov_5_1_5,
          provisionStatus: 'M C F (14, e)',
          description: l10n.p_5_1_5_desc),

      // --- Section: 5.2 Implement a means to manage reports of vulnerabilities ---
      l10n.section_5_2_title,
      ThreatData(
          provisionName: l10n.prov_5_2_1,
          provisionStatus: 'M',
          description: l10n.p_5_2_1_desc),
      ThreatData(
          provisionName: l10n.prov_5_2_2,
          provisionStatus: 'R',
          description: l10n.p_5_2_2_desc),
      ThreatData(
          provisionName: l10n.prov_5_2_3,
          provisionStatus: 'R',
          description: l10n.p_5_2_3_desc),

      // --- Section: 5.3 Keep software updated ---
      l10n.section_5_3_title,
      ThreatData(
          provisionName: l10n.prov_5_3_1,
          provisionStatus: 'R F (f)',
          description: l10n.p_5_3_1_desc),
      ThreatData(
          provisionName: l10n.prov_5_3_2,
          provisionStatus: 'M C (15)',
          description: l10n.p_5_3_2_desc),
      ThreatData(
          provisionName: l10n.prov_5_3_3,
          provisionStatus: 'M F (g)',
          description: l10n.p_5_3_3_desc),
      ThreatData(
          provisionName: l10n.prov_5_3_4A,
          provisionStatus: 'R F (g)',
          description: l10n.p_5_3_4A_desc),
      ThreatData(
          provisionName: l10n.prov_5_3_4B,
          provisionStatus: 'R F (h)',
          description: l10n.p_5_3_4B_desc),
      ThreatData(
          provisionName: l10n.prov_5_3_5,
          provisionStatus: 'R F (g)',
          description: l10n.p_5_3_5_desc),
      ThreatData(
          provisionName: l10n.prov_5_3_6A,
          provisionStatus: 'R F (h)',
          description: l10n.p_5_3_6A_desc),
      ThreatData(
          provisionName: l10n.prov_5_3_6B,
          provisionStatus: 'R F (i)',
          description: l10n.p_5_3_6B_desc),
      ThreatData(
          provisionName: l10n.prov_5_3_7,
          provisionStatus: 'M F (g)',
          description: l10n.p_5_3_7_desc),
      ThreatData(
          provisionName: l10n.prov_5_3_8,
          provisionStatus: 'M C (12)',
          description: l10n.p_5_3_8_desc),
      ThreatData(
          provisionName: l10n.prov_5_3_9,
          provisionStatus: 'R F (g)',
          description: l10n.p_5_3_9_desc),
      ThreatData(
          provisionName: l10n.prov_5_3_10,
          provisionStatus: 'M F (j)',
          description: l10n.p_5_3_10_desc),
      ThreatData(
          provisionName: l10n.prov_5_3_11,
          provisionStatus: 'R C (12)',
          description: l10n.p_5_3_11_desc),
      ThreatData(
          provisionName: l10n.prov_5_3_12,
          provisionStatus: 'R C (12)',
          description: l10n.p_5_3_12_desc),
      ThreatData(
          provisionName: l10n.prov_5_3_13,
          provisionStatus: 'M',
          description: l10n.p_5_3_13_desc),
      ThreatData(
          provisionName: l10n.prov_5_3_14,
          provisionStatus: 'R C (3)',
          description: l10n.p_5_3_14_desc),
      ThreatData(
          provisionName: l10n.prov_5_3_15A,
          provisionStatus: 'R C (3)',
          description: l10n.p_5_3_15A_desc),
      ThreatData(
          provisionName: l10n.prov_5_3_15B,
          provisionStatus: 'R C (3)',
          description: l10n.p_5_3_15B_desc),
      ThreatData(
          provisionName: l10n.prov_5_3_16,
          provisionStatus: 'M',
          description: l10n.p_5_3_16_desc),

      l10n.section_5_4_title,
      ThreatData(
          provisionName: l10n.prov_5_4_1,
          provisionStatus: 'M F (k)',
          description: l10n.p_5_4_1_desc),
      ThreatData(
          provisionName: l10n.prov_5_4_2,
          provisionStatus: 'M F (l)',
          description: l10n.p_5_4_2_desc),
      ThreatData(
          provisionName: l10n.prov_5_4_3,
          provisionStatus: 'M',
          description: l10n.p_5_4_3_desc),
      ThreatData(
          provisionName: l10n.prov_5_4_4,
          provisionStatus: 'M F (m)',
          description: l10n.p_5_4_4_desc),

      l10n.section_5_5_title,
      ThreatData(
          provisionName: l10n.prov_5_5_1,
          provisionStatus: 'M',
          description: l10n.p_5_5_1_desc),
      ThreatData(
          provisionName: l10n.prov_5_5_2,
          provisionStatus: 'R',
          description: l10n.p_5_5_2_desc),
      ThreatData(
          provisionName: l10n.prov_5_5_3,
          provisionStatus: 'R',
          description: l10n.p_5_5_3_desc),
      ThreatData(
          provisionName: l10n.prov_5_5_4,
          provisionStatus: 'R',
          description: l10n.p_5_5_4_desc),
      ThreatData(
          provisionName: l10n.prov_5_5_5,
          provisionStatus: 'M F (n)',
          description: l10n.p_5_5_5_desc),
      ThreatData(
          provisionName: l10n.prov_5_5_6,
          provisionStatus: 'R F (o)',
          description: l10n.p_5_5_6_desc),
      ThreatData(
          provisionName: l10n.prov_5_5_7,
          provisionStatus: 'M F (o)',
          description: l10n.p_5_5_7_desc),
      ThreatData(
          provisionName: l10n.prov_5_5_8,
          provisionStatus: 'M C (16)',
          description: l10n.p_5_5_8_desc),

      l10n.section_5_6_title,
      ThreatData(
          provisionName: l10n.prov_5_6_1,
          provisionStatus: 'M F (p)',
          description: l10n.p_5_6_1_desc),
      ThreatData(
          provisionName: l10n.prov_5_6_2,
          provisionStatus: 'M',
          description: l10n.p_5_6_2_desc),
      ThreatData(
          provisionName: l10n.prov_5_6_3,
          provisionStatus: 'R',
          description: l10n.p_5_6_3_desc),
      ThreatData(
          provisionName: l10n.prov_5_6_4A,
          provisionStatus: 'M F (q)',
          description: l10n.p_5_6_4A_desc),
      ThreatData(
          provisionName: l10n.prov_5_6_4B,
          provisionStatus: 'R F (r)',
          description: l10n.p_5_6_4B_desc),
      ThreatData(
          provisionName: l10n.prov_5_6_5,
          provisionStatus: 'R',
          description: l10n.p_5_6_5_desc),
      ThreatData(
          provisionName: l10n.prov_5_6_6,
          provisionStatus: 'R',
          description: l10n.p_5_6_6_desc),
      ThreatData(
          provisionName: l10n.prov_5_6_7,
          provisionStatus: 'R',
          description: l10n.p_5_6_7_desc),
      ThreatData(
          provisionName: l10n.prov_5_6_8,
          provisionStatus: 'R',
          description: l10n.p_5_6_8_desc),
      ThreatData(
          provisionName: l10n.prov_5_6_9,
          provisionStatus: 'R',
          description: l10n.p_5_6_9_desc),

      l10n.section_5_7_title,
      ThreatData(
          provisionName: l10n.prov_5_7_1,
          provisionStatus: 'R',
          description: l10n.p_5_7_1_desc),
      ThreatData(
          provisionName: l10n.prov_5_7_2,
          provisionStatus: 'R F (s)',
          description: l10n.p_5_7_2_desc),

      l10n.section_5_8_title,
      ThreatData(
          provisionName: l10n.prov_5_8_1,
          provisionStatus: 'R F (t)',
          description: l10n.p_5_8_1_desc),
      ThreatData(
          provisionName: l10n.prov_5_8_2,
          provisionStatus: 'M F (u)',
          description: l10n.p_5_8_2_desc),
      ThreatData(
          provisionName: l10n.prov_5_8_3,
          provisionStatus: 'M F (v)',
          description: l10n.p_5_8_3_desc),

      l10n.section_5_9_title,
      ThreatData(
          provisionName: l10n.prov_5_9_1,
          provisionStatus: 'R',
          description: l10n.p_5_9_1_desc),
      ThreatData(
          provisionName: l10n.prov_5_9_2,
          provisionStatus: 'R',
          description: l10n.p_5_9_2_desc),
      ThreatData(
          provisionName: l10n.prov_5_9_3,
          provisionStatus: 'R',
          description: l10n.p_5_9_3_desc),

      l10n.section_5_10_title,
      ThreatData(
          provisionName: l10n.prov_5_10_1,
          provisionStatus: 'R F (w)',
          description: l10n.p_5_10_1_desc),

      l10n.section_5_11_title,
      ThreatData(
          provisionName: l10n.prov_5_11_1,
          provisionStatus: 'M',
          description: l10n.p_5_11_1_desc),
      ThreatData(
          provisionName: l10n.prov_5_11_2,
          provisionStatus: 'R F (x)',
          description: l10n.p_5_11_2_desc),
      ThreatData(
          provisionName: l10n.prov_5_11_3,
          provisionStatus: 'R',
          description: l10n.p_5_11_3_desc),
      ThreatData(
          provisionName: l10n.prov_5_11_4,
          provisionStatus: 'R',
          description: l10n.p_5_11_4_desc),

      l10n.section_5_12_title,
      ThreatData(
          provisionName: l10n.prov_5_12_1,
          provisionStatus: 'R',
          description: l10n.p_5_12_1_desc),
      ThreatData(
          provisionName: l10n.prov_5_12_2,
          provisionStatus: 'R',
          description: l10n.p_5_12_2_desc),
      ThreatData(
          provisionName: l10n.prov_5_12_3,
          provisionStatus: 'R',
          description: l10n.p_5_12_3_desc),

      l10n.section_5_13_title,
      ThreatData(
          provisionName: l10n.prov_5_13_1A,
          provisionStatus: 'M',
          description: l10n.p_5_13_1A_desc),
      ThreatData(
          provisionName: l10n.prov_5_13_1B,
          provisionStatus: 'M',
          description: l10n.p_5_13_1B_desc),

      l10n.section_6_title,
      ThreatData(
          provisionName: l10n.prov_6_1,
          provisionStatus: 'M',
          description: l10n.p_6_1_desc),
      ThreatData(
          provisionName: l10n.prov_6_2,
          provisionStatus: 'M F (y)',
          description: l10n.p_6_2_desc),
      ThreatData(
          provisionName: l10n.prov_6_3A,
          provisionStatus: 'M F (y)',
          description: l10n.p_6_3A_desc),
      ThreatData(
          provisionName: l10n.prov_6_3B,
          provisionStatus: 'M F (y)',
          description: l10n.p_6_3B_desc),
      ThreatData(
          provisionName: l10n.prov_6_4,
          provisionStatus: 'R F (w)',
          description: l10n.p_6_4_desc),
      ThreatData(
          provisionName: l10n.prov_6_5,
          provisionStatus: 'M F (w)',
          description: l10n.p_6_5_desc),
      ThreatData(
          provisionName: l10n.prov_6_6,
          provisionStatus: 'M F (z)',
          description: l10n.p_6_6_desc),
      ThreatData(
          provisionName: l10n.prov_6_7,
          provisionStatus: 'R F (aa)',
          description: l10n.p_6_7_desc),
      ThreatData(
          provisionName: l10n.prov_6_8,
          provisionStatus: 'R F (z)',
          description: l10n.p_6_8_desc),
      // Add more ThreatData objects for each threat from the standard
    ];

    int totalItems = allItemsBlueprint.length;
    if (totalItems == 0) {
      if (mounted) {
        // Check mounted before setState
        setState(() {
          _threatDataList = []; // Ensure it's empty if blueprint is empty
        });
      }
      onProgress(1.0);
      return;
    }

    for (int i = 0; i < totalItems; i++) {
      if (!mounted) return; // Stop if widget is disposed during the loop
      newItems.add(allItemsBlueprint[i]);
      onProgress((i + 1) / totalItems);
      // Add a small delay to make the progress bar visible and allow UI to update.
      await Future.delayed(
          const Duration(milliseconds: 5)); // Adjust duration if needed
    }

    if (mounted) {
      // Assign the fully constructed list to the state variable
      _threatDataList = newItems;
    }
  }

  @override
  void dispose() {
    _productNameController.dispose(); // Dispose the controller
    super.dispose();
  }

  // Placeholder function for generating PDF
  Future<void> _generatePdf(BuildContext context) async {
    // Accept BuildContext
    final pdf = pw.Document();

    // Load a font that supports the characters you need (like Inter)
    // Ensure you have the font file in your assets folder and declared in pubspec.yaml
    // final fontData = await rootBundle.load("assets/fonts/Inter-Regular.ttf");
    // final ttf = pw.Font.ttf(fontData);
    // final boldFontData = await rootBundle.load("assets/fonts/Inter-Bold.ttf");
    // final boldTtf = pw.Font.ttf(boldFontData);
    // final pw.ThemeData theme = pw.ThemeData.withFont(base: ttf, bold: boldTtf);

    // Define table headers
    // Get localizations from the context
    final l10n = AppLocalizations.of(context)!;
    final headers = [
      l10n.provisionNameHeader,
      l10n.provisionStatusHeader,
      l10n.applicableHeader,
      l10n.likelihoodHeader,
      l10n.impactHeader,
      l10n.statusHeader,
      l10n.riskScoreHeader,
      l10n.notesHeader
    ];

    // Filter out non-ThreatData items (headers) before mapping
    final data = _threatDataList.whereType<ThreatData>().map((threat) {
      return [
        threat.provisionName, // Use provisionName for the first column
        // threat.description, // Could add description as another column if needed
        threat.provisionStatus,
        _capitalize(threat.applicable),
        _capitalize(threat.likelihood),
        _capitalize(threat.impact),
        _capitalize(threat.status),
        threat.riskScore,
        threat.notes,
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        // theme: theme, // Apply the theme with the loaded font
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                  // Use localized title
                  '${l10n.appTitle} Report', // Append 'Report' or adjust as needed
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 18)),
            ),
            pw.SizedBox(height: 10),
            pw.Paragraph(
              text: // Use localized label
                  '${l10n.productNameLabel}: ${_productName.isNotEmpty ? _productName : l10n.notSpecified}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: data,
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft, // Threat Description
                1: pw.Alignment.center, // Applicable
                2: pw.Alignment.center, // Likelihood
                3: pw.Alignment.center, // Impact
                4: pw.Alignment.center, // Status
                5: pw.Alignment.center, // Risk Score
                6: pw.Alignment.centerLeft, // Notes
              },
              // Apply cell styling based on risk score (more complex)
              // You might need to build the table row by row for complex styling
              columnWidths: {
                0: const pw.FlexColumnWidth(3), // Threat Description wider
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1), // Status
                5: const pw.FlexColumnWidth(1), // Risk Score
                6: const pw.FlexColumnWidth(2), // Notes wider
              },
            ),
            pw.SizedBox(height: 20),
            pw.Paragraph(
              text: // Use localized note
                  l10n.riskScoreCalculationNote,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ];
        },
      ),
    );

    // Save or share the PDF
    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'threat_assessment_report.pdf');

    // Or save to device (requires path_provider and permissions on mobile)
    // final Uint8List bytes = await pdf.save();
    // final Directory output = await getTemporaryDirectory(); // Or getApplicationDocumentsDirectory
    // final File file = File("${output.path}/threat_assessment_report.pdf");
    // await file.writeAsBytes(bytes);
    // print("PDF saved to: ${file.path}");
  }

  // Placeholder function for creating a shareable link
  Future<void> _createShareLink() async {
    final l10n = AppLocalizations.of(context)!;
    const String staticLink = "https://iotrisktool.com/";

    // 1. Construct the new URI (now static)
    // final newUri = Uri.base.replace(queryParameters: queryParameters); // Old dynamic link
    final newUri = Uri.parse(staticLink); // New static link

    // 4. Copy to clipboard
    await Clipboard.setData(ClipboardData(text: newUri.toString()));
    // Or directly:
    // await Clipboard.setData(const ClipboardData(text: staticLink));

    // 5. Show SnackBar confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.linkCopiedMessage),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Callback function for ThreatRow to update the state
  void _updateThreatData(int index, ThreatData updatedData) {
    setState(() {
      _threatDataList[index] = updatedData;
    });
  }

  // Helper to capitalize strings for PDF
  String _capitalize(String s) {
    if (s.isEmpty || s == 'na') return 'N/A';
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.appTitle), // Use l10n here for AppBar title
          centerTitle: true,
          actions: [_buildLanguageDropdown(context)],
          backgroundColor: Colors.blue[700],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                '${l10n.loadingMessage} ${(_loadingProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Main content of the page once loading is complete
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle), // Use l10n here
        centerTitle: true,
        actions: [_buildLanguageDropdown(context)],
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: 10.0, vertical: 15.0), // Adjusted padding
        child: Center(
          child: Container(
            constraints:
                const BoxConstraints(maxWidth: 1200), // Max width for the table
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Column(
                    children: [
                      Text(
                        l10n.pageDescription1, // Use localized string
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 14.0,
                            color: Colors.black54), // Adjusted font size
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        l10n.pageDescription2, // Use localized string
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 14.0,
                            color: Colors.black54), // Adjusted font size
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        l10n.pageDescription3, // Use localized string
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12.0,
                            color: Colors.red), // Adjusted font size
                      ),
                    ],
                  ),
                ),
                // --- Product Name Input ---
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: 20.0, left: 16.0, right: 16.0),
                  child: TextField(
                    controller: _productNameController,
                    decoration: InputDecoration(
                      labelText: l10n.productNameLabel, // Use localized string
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                Card(
                  // Using a Card for a nice visual container like the HTML version
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: SingleChildScrollView(
                    // This SingleChildScrollView enables horizontal scrolling for the table content
                    // when the content width (defined by the SizedBox below) exceeds the viewport width.
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      // Ensure the content has a fixed width for Expanded to work
                      width: 1200.0, // Min width for scrollable content
                      child: Padding(
                        padding: const EdgeInsets.all(
                            8.0), // Inner padding for the table content
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment
                              .stretch, // Stretch children to fill the width
                          children: [
                            // Table Header
                            ThreatRow(
                              provisionName: l10n.provisionNameHeader,
                              provisionStatus: l10n.provisionStatusHeader,
                              isHeader: true,
                              applicable: l10n.applicableHeader,
                              likelihood: l10n.likelihoodHeader,
                              impact: l10n.impactHeader,
                              status: l10n.statusHeader,
                              riskScore: l10n.riskScoreHeader,
                              notes: l10n.notesHeader,
                            ),
                            const Divider(height: 1.0, color: Colors.grey),
                            // Dynamically build rows and section headers
                            // Replaced the for loop with ListView.builder for better performance,
                            // especially with longer lists. It builds items lazily as they scroll into view.
                            ListView.builder(
                              shrinkWrap:
                                  true, // Essential when nesting ListView inside a Column or another scroll view.
                              physics:
                                  const NeverScrollableScrollPhysics(), // The parent SingleChildScrollView handles scrolling.
                              itemCount: _threatDataList.length,
                              itemBuilder: (BuildContext context, int index) {
                                // _buildRowOrHeader correctly differentiates between String headers and ThreatData rows.
                                return _buildRowOrHeader(
                                    _threatDataList[index], index);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text(
                    l10n.riskScoreCalculationNote, // Use localized string
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(fontSize: 14.0, color: Colors.black54),
                  ),
                ),
                // Added Notes Section
                Padding(
                  padding:
                      const EdgeInsets.only(top: 20.0, left: 16.0, right: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.notesSectionTitle, // Use localized string
                        style: const TextStyle(
                            fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        l10n.conditionSectionTitle, // Use localized string
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(l10n.conditionNoteItem1),
                      Text(l10n.conditionNoteItem2),
                      Text(l10n.conditionNoteItem3),
                      Text(l10n.conditionNoteItem4),
                      Text(l10n.conditionNoteItem5),
                      const SizedBox(height: 12.0),
                      Text(
                        l10n.featureSectionTitle, // Use localized string
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(l10n.featureNoteItemA),
                      Text(l10n.featureNoteItemB),
                      Text(l10n.featureNoteItemC),
                      Text(l10n.featureNoteItemD),
                      Text(l10n.featureNoteItemE),
                      Text(l10n.featureNoteItemF),
                      Text(l10n.featureNoteItemG),
                      Text(l10n.featureNoteItemH),
                      Text(l10n.featureNoteItemI),
                      Text(l10n.featureNoteItemJ),
                      Text(l10n.featureNoteItemK),
                      Text(l10n.featureNoteItemL),
                      Text(l10n.featureNoteItemM),
                      Text(l10n.featureNoteItemN),
                      Text(l10n.featureNoteItemO),
                      Text(l10n.featureNoteItemP),
                      Text(l10n.featureNoteItemQ),
                      Text(l10n.featureNoteItemR),
                      Text(l10n.featureNoteItemS),
                      Text(l10n.featureNoteItemT),
                      Text(l10n.featureNoteItemU),
                      Text(l10n.featureNoteItemV),
                      Text(l10n.featureNoteItemW),
                      Text(l10n.featureNoteItemX),
                      Text(l10n.featureNoteItemY),
                      Text(l10n.featureNoteItemZ),
                      Text(l10n.featureNoteItemAA),
                    ],
                  ),
                ),
                // End of Added Notes Section
                const SizedBox(height: 20.0), // Space between table and buttons
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Center the buttons
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          _generatePdf(context), // Pass context here
                      child: Text(l10n.generatePdfButton),
                    ),
                    const SizedBox(width: 20.0), // Space between buttons
                    ElevatedButton(
                      onPressed:
                          _createShareLink, // Call the placeholder function
                      child: Text(l10n.shareLinkButton),
                    ),
                  ],
                ),
                const SizedBox(height: 40.0), // Space before the footer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Text(
                        l10n.repositoryInfo(
                            'https://github.com/ShareASoftware/iotrisktool'),
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 12.0, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        l10n.collaborationInvitation,
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 12.0, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0), // Space at the very bottom
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget to build the language selection dropdown
  Widget _buildLanguageDropdown(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Get the current language code
    final currentLanguageCode = Localizations.localeOf(context).languageCode;
    // Find the exact Locale object from the supported list that matches the current language code
    final currentLocale = AppLocalizations.supportedLocales.firstWhere(
      (locale) => locale.languageCode == currentLanguageCode,
      orElse: () => AppLocalizations
          .supportedLocales.first, // Fallback to the first supported locale
    );
    return DropdownButtonHideUnderline(
      child: DropdownButton<Locale>(
        value: currentLocale,
        icon: const Icon(Icons.language, color: Colors.white),
        // Generate items directly from the supported locales list
        items: AppLocalizations.supportedLocales.map((Locale locale) {
          final langName =
              locale.languageCode == 'en' ? l10n.langEnglish : l10n.langItalian;
          return DropdownMenuItem<Locale>(value: locale, child: Text(langName));
        }).toList(),
        onChanged: (Locale? locale) {
          if (locale != null) {
            MyApp.setLocale(context, locale); // Call the static method
          }
        },
      ),
    );
  }

  // Helper to build either a header or a ThreatRow
  Widget _buildRowOrHeader(dynamic item, int index) {
    if (item is String) {
      // Build a header widget
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Text(
              item, // The header text
              style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 25, 118, 210)),
            ),
          ),
          const Divider(height: 1.0, color: Colors.grey),
        ],
      );
    } else if (item is ThreatData) {
      // Build a ThreatRow widget
      return Column(
        // Wrap in column to add divider easily
        children: [
          ThreatRow(
            key: ValueKey(item.provisionName), // Use a unique key
            threatData: item,
            onChanged: (updatedData) => _updateThreatData(index, updatedData),
            provisionName: item.provisionName,
            provisionStatus: item.provisionStatus,
          ),
          const Divider(height: 1.0, color: Colors.grey),
        ],
      );
    }
    return const SizedBox.shrink(); // Should not happen
  }
}

class ThreatRow extends StatefulWidget {
  final bool isHeader;

  const ThreatRow({
    super.key,
    required this.provisionName,
    this.provisionStatus,
    this.isHeader = false,
    this.applicable,
    this.likelihood,
    this.impact,
    this.status,
    this.riskScore,
    this.notes,
    this.threatData,
    this.onChanged,
  }) : assert(isHeader &&
                provisionName != null &&
                provisionStatus != null &&
                applicable != null &&
                likelihood != null &&
                impact != null &&
                status != null &&
                riskScore != null &&
                notes != null || // If header, all text fields must be provided
            !isHeader && threatData != null && onChanged != null);

  // Fields for Header Row
  final String? provisionName;
  final String? provisionStatus;
  final String? applicable;
  final String? likelihood;
  final String? impact;
  final String? status;
  final String? riskScore;
  final String? notes;

  // Fields for Data Row
  final ThreatData? threatData;
  final Function(ThreatData)? onChanged;

  @override
  _ThreatRowState createState() => _ThreatRowState();
}

class _ThreatRowState extends State<ThreatRow> {
  // State is now primarily for the TextEditingController and calculated risk display
  late TextEditingController _notesController = TextEditingController();
  String _calculatedRiskScore = 'N/A';
  Color _calculatedRiskColor = Colors.grey;
  PdfColor _calculatedRiskPdfColor = PdfColors.grey; // For PDF

  // Local state for dropdowns to avoid rebuilding the whole list on every dropdown change internally
  // These will be initialized from widget.threatData and used to trigger the onChanged callback
  String? _selectedApplicable;
  String? _selectedLikelihood;
  String? _selectedImpact;
  String? _selectedStatus;

  // Mapping dropdown values to scores
  final Map<String, int> _scoreMap = {
    'na': 0,
    'yes': 1,
    'low': 1,
    'medium': 2,
    'high': 3,
  };

  @override
  void initState() {
    super.initState();
    if (!widget.isHeader) {
      _notesController = TextEditingController(text: widget.threatData!.notes);
      _notesController.addListener(_onNotesChanged);
      // Initialize local dropdown state
      _selectedApplicable = widget.threatData!.applicable;
      _selectedLikelihood = widget.threatData!.likelihood;
      _selectedImpact = widget.threatData!.impact;
      _selectedStatus = widget.threatData!.status;
      // Calculate initial risk score based on passed data
      _calculateRiskScore(
        applicable: widget.threatData!.applicable,
        likelihood: widget.threatData!.likelihood,
        impact: widget.threatData!.impact,
      );
    } else {
      // For header row, create a dummy controller
      _notesController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _notesController.removeListener(_onNotesChanged); // Clean up listener
    super.dispose();
  }

  // Called when notes text field changes
  void _onNotesChanged() {
    if (!widget.isHeader && widget.onChanged != null) {
      // Update the parent state immediately on text change
      _updateParentState(notes: _notesController.text);
    }
  }

  // Calculate risk score based on provided values
  void _calculateRiskScore({
    required String applicable,
    required String likelihood,
    required String impact,
  }) {
    String scoreText = 'N/A';
    Color displayColor = Colors.grey;
    PdfColor pdfColor = PdfColors.grey;

    if (applicable == 'yes') {
      final int likelihoodScore = _scoreMap[likelihood] ?? 0;
      final int impactScore = _scoreMap[impact] ?? 0;

      if (likelihoodScore > 0 && impactScore > 0) {
        final int calculatedRisk = likelihoodScore * impactScore;

        if (calculatedRisk >= 6) {
          scoreText = 'High ($calculatedRisk)';
          displayColor = Colors.red[700]!;
          pdfColor = PdfColors.red700;
        } else if (calculatedRisk >= 3) {
          scoreText = 'Medium ($calculatedRisk)';
          displayColor = Colors.orange[700]!;
          pdfColor = PdfColors.orange700;
        } else if (calculatedRisk >= 1) {
          scoreText = 'Low ($calculatedRisk)';
          displayColor = Colors.green[700]!;
          pdfColor = PdfColors.green700;
        }
      }
    }

    // Update local state for display, but don't call setState here
    // as it will be triggered by the parent's setState when data is updated.
    _calculatedRiskScore = scoreText;
    _calculatedRiskColor = displayColor;
    _calculatedRiskPdfColor = pdfColor;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Get localizations instance
    // Define text style based on whether it's a header or not
    final TextStyle textStyle = widget.isHeader
        ? const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 12.0, color: Colors.black87)
        : const TextStyle(fontSize: 14.0, color: Colors.black87);

    // Define padding for cells
    const EdgeInsets cellPadding =
        EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);

    // Helper function to create a header cell
    Widget buildHeaderCell(String text) {
      return Expanded(
        // Define flex values for header columns
        flex: text.contains(l10n.provisionNameHeader)
            ? 3
            : text.contains(l10n.notesHeader)
                ? 2
                : text.contains(l10n.statusHeader) // Check for statusHeader
                    ? 1 // Flex for statusHeader
                    : // Adjust if needed
                    1, // Default flex for other columns
        child: Padding(
          padding: cellPadding,
          child: Text(
            text,
            style: textStyle,
            overflow: TextOverflow.ellipsis, // Prevent overflow
            maxLines: 2, // Allow up to 2 lines
          ),
        ),
      );
    }

    if (widget.isHeader) {
      return IntrinsicHeight(
        // Make row height adapt to content
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Stretch cells vertically
          children: [
            buildHeaderCell(widget.provisionName!),
            buildHeaderCell(widget.provisionStatus!),
            buildHeaderCell(widget.applicable!),
            buildHeaderCell(widget.likelihood!),
            buildHeaderCell(widget.impact!),
            buildHeaderCell(widget.status!), // Status header cell
            buildHeaderCell(widget.riskScore!),
            buildHeaderCell(widget.notes!),
          ],
        ),
      );
    } else {
      return IntrinsicHeight(
        // Make row height adapt to content
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Stretch cells vertically
          children: [
            Expanded(
              // Threat Description cell
              flex: 3, // Match header flex
              child: Padding(
                padding: cellPadding,
                child: Text(
                  widget.provisionName!,
                  style: textStyle,
                ),
              ),
            ),
            Expanded(
              // Threat Description cell
              flex: 1, // Match header flex (adjust if needed)
              child: Padding(
                padding: cellPadding,
                child: Text(widget.provisionStatus ?? '', style: textStyle),
              ),
            ),
            Expanded(
              // Applicable cell
              flex: 1,
              child: Padding(
                padding: cellPadding,
                child: DropdownButton<String>(
                  isExpanded: true, // Make dropdown take full width
                  value: _selectedApplicable, // Use local state for display
                  items: [
                    // Removed const
                    const DropdownMenuItem(
                        value: 'na',
                        child: Text(
                            'N/A')), // N/A usually doesn't need translation in this context
                    DropdownMenuItem(
                        value: 'yes', child: Text(l10n.applicableYes)),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        // Update local state for immediate UI feedback
                        _selectedApplicable = newValue;
                        _updateParentState(
                            applicable: newValue); // Notify parent
                      });
                    }
                  },
                ),
              ),
            ),
            Expanded(
              // Likelihood cell
              flex: 1,
              child: Padding(
                padding: cellPadding,
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedLikelihood, // Use local state
                  items: [
                    // Removed const
                    const DropdownMenuItem(value: 'na', child: Text('N/A')),
                    DropdownMenuItem(value: 'low', child: Text(l10n.levelLow)),
                    DropdownMenuItem(
                        value: 'medium', child: Text(l10n.levelMedium)),
                    DropdownMenuItem(
                        value: 'high', child: Text(l10n.levelHigh)),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedLikelihood = newValue;
                        _updateParentState(
                            likelihood: newValue); // Notify parent
                      });
                    }
                  },
                ),
              ),
            ),
            Expanded(
              // Impact cell
              flex: 1,
              child: Padding(
                padding: cellPadding,
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedImpact, // Use local state
                  items: [
                    // Removed const
                    const DropdownMenuItem(value: 'na', child: Text('N/A')),
                    DropdownMenuItem(value: 'low', child: Text(l10n.levelLow)),
                    DropdownMenuItem(
                        value: 'medium', child: Text(l10n.levelMedium)),
                    DropdownMenuItem(
                        value: 'high', child: Text(l10n.levelHigh)),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedImpact = newValue;
                        _updateParentState(impact: newValue); // Notify parent
                      });
                    }
                  },
                ),
              ),
            ),
            Expanded(
              // Status cell
              flex: 1,
              child: Padding(
                padding: cellPadding,
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedStatus, // Use local state
                  items: [
                    // Removed const
                    DropdownMenuItem(
                        value: 'open', child: Text(l10n.statusOpen)),
                    DropdownMenuItem(
                        value: 'mitigated', child: Text(l10n.statusMitigated)),
                    DropdownMenuItem(
                        value: 'accepted', child: Text(l10n.statusAccepted)),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedStatus = newValue;
                        _updateParentState(status: newValue); // Notify parent
                      });
                    }
                  },
                ),
              ),
            ),
            Expanded(
              // Risk Score cell
              flex: 1,
              child: Padding(
                padding: cellPadding,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    // Use calculated color from state
                    color: _calculatedRiskColor,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Center(
                    // Center the text within the container
                    child: Text(
                      // Use calculated score from state
                      _calculatedRiskScore,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // White text for better contrast
                        fontSize: 12.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ), // Closes Expanded for Risk Score cell
            ),
            Expanded(
              // Notes cell
              flex: 2,
              child: Padding(
                padding: cellPadding,
                child: TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    // Removed const
                    hintText: l10n.enterNotesHint, // Use localized string
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 8.0),
                  ),
                  maxLines: null, // Allow multiple lines
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  // Helper method to recalculate score and notify parent
  void _updateParentState({
    String? applicable,
    String? likelihood,
    String? impact,
    String? status,
    String? notes,
    // Optional risk params if calculation happens elsewhere, but better to calculate here
    // String? riskScore,
    // PdfColor? riskColor,
  }) {
    // Use current local state for values not being updated in this call
    final currentApplicable = applicable ?? _selectedApplicable!;
    final currentLikelihood = likelihood ?? _selectedLikelihood!;
    final currentImpact = impact ?? _selectedImpact!;

    // Recalculate risk score based on potentially updated values
    _calculateRiskScore(
        applicable: currentApplicable,
        likelihood: currentLikelihood,
        impact: currentImpact);

    // Create updated ThreatData object
    final updatedData = widget.threatData!.copyWith(
        applicable: currentApplicable,
        likelihood: currentLikelihood,
        impact: currentImpact,
        status: status ?? _selectedStatus,
        notes: notes ?? _notesController.text,
        riskScore: _calculatedRiskScore, // Use the newly calculated score
        riskColor: _calculatedRiskPdfColor // Use the newly calculated color
        );

    // Call the parent's callback
    widget.onChanged!(updatedData);
  }
}
