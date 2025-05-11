import 'package:flutter/material.dart';
// Import PDF generation packages
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
// Import localization packages
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
  Locale _locale = const Locale('en'); // Default locale

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
      home: const ThreatAssessmentPage(),
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
  const ThreatAssessmentPage({super.key});

  @override
  _ThreatAssessmentPageState createState() => _ThreatAssessmentPageState();
}

class _ThreatAssessmentPageState extends State<ThreatAssessmentPage> {
  // Controller and variable for Product Name
  final TextEditingController _productNameController = TextEditingController();
  String _productName = '';
  // bool _isLoading = true; // State variable for loading indicator - Removed as data is static and loaded synchronously.

  // List to hold the state of all threat rows
// Using List<dynamic> to store Strings (headers) and ThreatData objects
  final List<dynamic> _threatDataList = [
    // --- Section: 5.0 Reporting implementation ---
    '5.0 Reporting implementation',
    ThreatData(
        provisionName: 'Provision 5.0-1',
        provisionStatus: 'M',
        description: 'Reporting implementation details'),

    // --- Subsection: 5.1 No universal default passwords ---
    '5.1 No universal default passwords',
    ThreatData(
        provisionName: 'Provision 5.1-1',
        provisionStatus: 'M F (a)',
        description: 'No universal default passwords'),
    ThreatData(
        provisionName: 'Provision 5.1-2',
        provisionStatus: 'M F (b)',
        description: 'Unique per-device passwords'),
    ThreatData(
        provisionName: 'Provision 5.1-2A',
        provisionStatus: 'R',
        description: 'Password complexity'),
    ThreatData(
        provisionName: 'Provision 5.1-3',
        provisionStatus: 'M F (c)',
        description: 'Authentication mechanism strength'),
    ThreatData(
        provisionName: 'Provision 5.1-4',
        provisionStatus: 'M F (d)',
        description: 'User guidance on password change'),
    ThreatData(
        provisionName: 'Provision 5.1-5',
        provisionStatus: 'M C F (14, e)',
        description: 'Brute-force mitigation'),

    // --- Section: 5.2 Implement a means to manage reports of vulnerabilities ---
    '5.2 Implement a means to manage reports of vulnerabilities',
    ThreatData(
        provisionName: 'Provision 5.2-1',
        provisionStatus: 'M',
        description: 'Vulnerability disclosure policy'),
    ThreatData(
        provisionName: 'Provision 5.2-2',
        provisionStatus: 'R',
        description: 'Contact point for reporting'),
    ThreatData(
        provisionName: 'Provision 5.2-3',
        provisionStatus: 'R',
        description: 'Acknowledgement of reports'),

    // --- Section: 5.3 Keep software updated ---
    '5.3 Keep software updated',
    ThreatData(
        provisionName: 'Provision 5.3-1',
        provisionStatus: 'R F (f)',
        description: 'Update policy definition'),
    ThreatData(
        provisionName: 'Provision 5.3-2',
        provisionStatus: 'M C (15)',
        description: 'Update mechanism'),
    ThreatData(
        provisionName: 'Provision 5.3-3',
        provisionStatus: 'M F (g)',
        description: 'Timely updates'),
    ThreatData(
        provisionName: 'Provision 5.3-4A',
        provisionStatus: 'R F (g)',
        description: 'Update availability notification'),
    ThreatData(
        provisionName: 'Provision 5.3-4B',
        provisionStatus: 'R F (h)',
        description: 'Automatic update option'),
    ThreatData(
        provisionName: 'Provision 5.3-5',
        provisionStatus: 'R F (g)',
        description: 'User control over updates'),
    ThreatData(
        provisionName: 'Provision 5.3-6A',
        provisionStatus: 'R F (h)',
        description: 'Update failure handling'),
    ThreatData(
        provisionName: 'Provision 5.3-6B',
        provisionStatus: 'R F (i)',
        description: 'Update notification details'),
    ThreatData(
        provisionName: 'Provision 5.3-7',
        provisionStatus: 'M F (g)',
        description: 'Update integrity verification'),
    ThreatData(
        provisionName: 'Provision 5.3-8',
        provisionStatus: 'M C (12)',
        description: 'Update authenticity verification'),
    ThreatData(
        provisionName: 'Provision 5.3-9',
        provisionStatus: 'R F (g)',
        description: 'Rollback mechanism'),
    ThreatData(
        provisionName: 'Provision 5.3-10',
        provisionStatus: 'M F (j)',
        description: 'Secure update delivery'),
    ThreatData(
        provisionName: 'Provision 5.3-11',
        provisionStatus: 'R C (12)',
        description: 'Update confidentiality'),
    ThreatData(
        provisionName: 'Provision 5.3-12',
        provisionStatus: 'R C (12)',
        description: 'Update source authentication'),
    ThreatData(
        provisionName: 'Provision 5.3-13',
        provisionStatus: 'M',
        description: 'Software component inventory'),
    ThreatData(
        provisionName: 'Provision 5.3-14',
        provisionStatus: 'R C (3)',
        description: 'Handling non-updateable components'),
    ThreatData(
        provisionName: 'Provision 5.3-15A',
        provisionStatus: 'R C (3)',
        description: 'Security implications of non-updateable components'),
    ThreatData(
        provisionName: 'Provision 5.3-15B',
        provisionStatus: 'R C (3)',
        description: 'User information on non-updateable components'),
    ThreatData(
        provisionName: 'Provision 5.3-16',
        provisionStatus: 'M',
        description: 'End-of-life policy'),

    // --- Section: 5.4 Securely store sensitive security parameters ---
    '5.4 Securely store sensitive security parameters',
    ThreatData(
        provisionName: 'Provision 5.4-1',
        provisionStatus: 'M F (k)',
        description: 'Storage protection'),
    ThreatData(
        provisionName: 'Provision 5.4-2',
        provisionStatus: 'M F (l)',
        description: 'Protection of hard-coded secrets'),
    ThreatData(
        provisionName: 'Provision 5.4-3',
        provisionStatus: 'M',
        description: 'Use of hardware security features'),
    ThreatData(
        provisionName: 'Provision 5.4-4',
        provisionStatus: 'M F (m)',
        description: 'Protection during transit/use'),

    // --- Section: 5.5 Communicate securely ---
    '5.5 Communicate securely',
    ThreatData(
        provisionName: 'Provision 5.5-1',
        provisionStatus: 'M',
        description: 'Use of secure protocols'),
    ThreatData(
        provisionName: 'Provision 5.5-2',
        provisionStatus: 'R',
        description: 'Protocol selection justification'),
    ThreatData(
        provisionName: 'Provision 5.5-3',
        provisionStatus: 'R',
        description: 'Cipher suite selection'),
    ThreatData(
        provisionName: 'Provision 5.5-4',
        provisionStatus: 'R',
        description: 'Certificate validation'),
    ThreatData(
        provisionName: 'Provision 5.5-5',
        provisionStatus: 'M F (n)',
        description: 'Secure configuration changes'),
    ThreatData(
        provisionName: 'Provision 5.5-6',
        provisionStatus: 'R F (o)',
        description: 'Secure transmission of critical parameters'),
    ThreatData(
        provisionName: 'Provision 5.5-7',
        provisionStatus: 'M F (o)',
        description: 'Protection of critical parameters in transit'),
    ThreatData(
        provisionName: 'Provision 5.5-8',
        provisionStatus: 'M C (16)',
        description: 'Secure storage of communication keys'),

    // --- Section: 5.6 Minimize exposed attack surfaces ---
    '5.6 Minimize exposed attack surfaces',
    ThreatData(
        provisionName: 'Provision 5.6-1',
        provisionStatus: 'M F (p)',
        description: 'Disable unused interfaces'),
    ThreatData(
        provisionName: 'Provision 5.6-2',
        provisionStatus: 'M',
        description: 'Minimize network services'),
    ThreatData(
        provisionName: 'Provision 5.6-3',
        provisionStatus: 'R',
        description: 'Justification for open ports'),
    ThreatData(
        provisionName: 'Provision 5.6-4A',
        provisionStatus: 'M F (q)',
        description: 'Disable debug interfaces'),
    ThreatData(
        provisionName: 'Provision 5.6-4B',
        provisionStatus: 'R F (r)',
        description: 'Secure physical debug interfaces'),
    ThreatData(
        provisionName: 'Provision 5.6-5',
        provisionStatus: 'R',
        description: 'Limit service privileges'),
    ThreatData(
        provisionName: 'Provision 5.6-6',
        provisionStatus: 'R',
        description: 'Input validation'),
    ThreatData(
        provisionName: 'Provision 5.6-7',
        provisionStatus: 'R',
        description: 'Resource management'),
    ThreatData(
        provisionName: 'Provision 5.6-8',
        provisionStatus: 'R',
        description: 'Secure default configuration'),
    ThreatData(
        provisionName: 'Provision 5.6-9',
        provisionStatus: 'R',
        description: 'Documentation of attack surface'),

    // --- Section: 5.7 Ensure software integrity ---
    '5.7 Ensure software integrity',
    ThreatData(
        provisionName: 'Provision 5.7-1',
        provisionStatus: 'R',
        description: 'Secure boot mechanism'),
    ThreatData(
        provisionName: 'Provision 5.7-2',
        provisionStatus: 'R F (s)',
        description: 'Runtime integrity protection'),

    // --- Section: 5.8 Ensure that personal data is secure ---
    '5.8 Ensure that personal data is secure',
    ThreatData(
        provisionName: 'Provision 5.8-1',
        provisionStatus: 'R F (t)',
        description: 'Data minimization'),
    ThreatData(
        provisionName: 'Provision 5.8-2',
        provisionStatus: 'M F (u)',
        description: 'Secure storage of personal data'),
    ThreatData(
        provisionName: 'Provision 5.8-3',
        provisionStatus: 'M F (v)',
        description: 'Secure processing of personal data'),

    // --- Section: 5.9 Make systems resilient to outages ---
    '5.9 Make systems resilient to outages',
    ThreatData(
        provisionName: 'Provision 5.9-1',
        provisionStatus: 'R',
        description: 'Handling network outages'),
    ThreatData(
        provisionName: 'Provision 5.9-2',
        provisionStatus: 'R',
        description: 'Handling power outages'),
    ThreatData(
        provisionName: 'Provision 5.9-3',
        provisionStatus: 'R',
        description: 'Recovery mechanisms'),

    // --- Section: 5.10 Examine system telemetry data ---
    '5.10 Examine system telemetry data',
    ThreatData(
        provisionName: 'Provision 5.10-1',
        provisionStatus: 'R F (w)',
        description: 'Telemetry data analysis'),

    // --- Section: 5.11 Make it easy for users to delete user data ---
    '5.11 Make it easy for users to delete user data',
    ThreatData(
        provisionName: 'Provision 5.11-1',
        provisionStatus: 'M',
        description: 'Data deletion mechanism (device)'),
    ThreatData(
        provisionName: 'Provision 5.11-2',
        provisionStatus: 'R F (x)',
        description: 'Data deletion mechanism (service)'),
    ThreatData(
        provisionName: 'Provision 5.11-3',
        provisionStatus: 'R',
        description: 'User guidance on data deletion'),
    ThreatData(
        provisionName: 'Provision 5.11-4',
        provisionStatus: 'R',
        description: 'Confirmation of deletion'),

    // --- Section: 5.12 Make installation and maintenance of devices easy ---
    '5.12 Make installation and maintenance of devices easy',
    ThreatData(
        provisionName: 'Provision 5.12-1',
        provisionStatus: 'R',
        description: 'Clear installation instructions'),
    ThreatData(
        provisionName: 'Provision 5.12-2',
        provisionStatus: 'R',
        description: 'Clear maintenance instructions'),
    ThreatData(
        provisionName: 'Provision 5.12-3',
        provisionStatus: 'R',
        description: 'Secure disposal instructions'),

    // --- Section: 5.13 Validate input data ---
    '5.13 Validate input data',
    ThreatData(
        provisionName: 'Provision 5.13-1A',
        provisionStatus: 'M',
        description: 'Input validation (network)'),
    ThreatData(
        provisionName: 'Provision 5.13-1B',
        provisionStatus: 'M',
        description: 'Input validation (local)'),

    // --- Section: 6 Data protection provisions for consumer IoT ---
    '6 Data protection provisions for consumer IoT',
    ThreatData(
        provisionName: 'Provision 6.1',
        provisionStatus: 'M',
        description: 'Privacy policy'),
    ThreatData(
        provisionName: 'Provision 6.2',
        provisionStatus: 'M F (y)',
        description: 'Consent mechanism'),
    ThreatData(
        provisionName: 'Provision 6.3A',
        provisionStatus: 'M F (y)',
        description: 'Withdrawal of consent'),
    ThreatData(
        provisionName: 'Provision 6.3B',
        provisionStatus: 'M F (y)',
        description: 'Effect of consent withdrawal'),
    ThreatData(
        provisionName: 'Provision 6.4',
        provisionStatus: 'R F (w)',
        description: 'Purpose limitation (telemetry)'),
    ThreatData(
        provisionName: 'Provision 6.5',
        provisionStatus: 'M F (w)',
        description: 'Transparency (telemetry)'),
    ThreatData(
        provisionName: 'Provision 6.6',
        provisionStatus: 'M F (z)',
        description: 'Transparency (data processing)'),
    ThreatData(
        provisionName: 'Provision 6.7',
        provisionStatus: 'R F (aa)',
        description: 'Data aggregation/anonymization'),
    ThreatData(
        provisionName: 'Provision 6.8',
        provisionStatus: 'R F (z)',
        description: 'User access to data'),
    // Add more ThreatData objects for each threat from the standard
  ];

  @override
  void initState() {
    super.initState();
    // The _isLoading state and Future.delayed have been removed because _threatDataList
    // is initialized synchronously. Displaying a loader here was artificial.
    // If data were truly loaded asynchronously in the future,
    // using a FutureBuilder would be a more appropriate pattern.
    // Listen to changes in the product name field
    _productNameController.addListener(() {
      if (mounted) {
        setState(() {
          _productName = _productNameController.text;
        });
      }
    });
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
  void _createShareLink() {
    // TODO: Implement shareable link logic here.
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
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        centerTitle: true,
        actions: [_buildLanguageDropdown(context)], // Add dropdown here
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
        // Removed _isLoading check, content is shown directly
        // Allows scrolling if content overflows
        padding: const EdgeInsets.symmetric(
            horizontal: 10.0, vertical: 15.0), // Adjusted padding
        child: Center(
          child: Container(
            constraints:
                const BoxConstraints(maxWidth: 1200), // Max width for the table
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 20.0),
                  child: Column(
                    children: [
                      Text(
                        'Based on Annex B, Table B.1: Use this table to identify potential threats to your IoT device and assess their risk.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.black54), // Adjusted font size
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'Fill in the \'Applicable\', \'Likelihood\', and \'Impact\' fields for each threat. The \'Risk Score\' will be calculated automatically.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.black54), // Adjusted font size
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'Note: This is a template. Please populate the data according to the requirements.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
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
                    decoration: const InputDecoration(
                      labelText: 'Product Name / System Under Assessment',
                      border: OutlineInputBorder(),
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
                              provisionName: AppLocalizations.of(context)!
                                  .provisionNameHeader,
                              provisionStatus: AppLocalizations.of(context)!
                                  .provisionStatusHeader,
                              isHeader: true,
                              applicable: AppLocalizations.of(context)!
                                  .applicableHeader,
                              likelihood: AppLocalizations.of(context)!
                                  .likelihoodHeader,
                              impact:
                                  AppLocalizations.of(context)!.impactHeader,
                              status:
                                  AppLocalizations.of(context)!.statusHeader,
                              riskScore:
                                  AppLocalizations.of(context)!.riskScoreHeader,
                              notes: AppLocalizations.of(context)!.notesHeader,
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
                const Padding(
                  padding: EdgeInsets.only(top: 20.0),
                  child: Text(
                    'Risk Score Calculation: (Likelihood Score * Impact Score). If Applicable is \'No\', Risk is N/A.\nScores: N/A=0, Low=1, Medium=2, High=3. Risk Levels: 1-2=Low (Green), 3-4=Medium (Amber), 6-9=High (Red).',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.0, color: Colors.black54),
                  ),
                ),
                // Added Notes Section
                const Padding(
                  padding: EdgeInsets.only(top: 20.0, left: 16.0, right: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notes:',
                        style: TextStyle(
                            fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'Condition:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('3) software components are not updateable;'),
                      Text('12) an update mechanism is implemented;'),
                      Text(
                          '14) the consumer IoT device has no resource constraint determined by the use case that prevents the implementation of a mechanism which makes successful brute-force attacks on authentication mechanisms via network interfaces impracticable;'),
                      Text(
                          '15) the consumer IoT device has no resource constraint determined by the use case that prevents the implementation of an update mechanism;'),
                      Text(
                          '16) existence of critical security parameters that relate to the consumer IoT device;'),
                      SizedBox(height: 12.0),
                      Text(
                        'Feature, capability or mechanism that needs to be present for the corresponding provision to apply:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                          'a) passwords can be used to authenticate users against the device or for machine-to-machine authentication;'),
                      Text(
                          'b) pre-installed unique per device passwords can be used to authenticate users against the device or for machine-to-machine authentication;'),
                      Text(
                          'c) cryptographic authentication mechanisms, including password based mechanisms, can be used to authenticate users against the consumer IoT device or for machine-to-machine authentication;'),
                      Text(
                          'd) authentication mechanisms can be used to authenticate users against the consumer IoT device;'),
                      Text(
                          'e) authentication mechanisms can be used for authenticating users or devices via network interfaces;'),
                      Text(
                          'f) software components that are not immutable due to security reasons;'),
                      Text(
                          'g) software components of the device can be updated;'),
                      Text('h) automatic software updates are supported;'),
                      Text(
                          'i) update notifications are provided when software updates are available;'),
                      Text(
                          'j) software updates can be delivered over a network interface;'),
                      Text(
                          'k) sensitive security parameters exist in persistent storage;'),
                      Text(
                          'l) hard-coded unique per device identities are used in the consumer IoT device for security purposes;'),
                      Text(
                          'm) critical security parameters are used for integrity or authenticity checks of software updates or for protection of communication with associated services;'),
                      Text(
                          'n) the consumer IoT device allows security-relevant changes in configuration via a network interface;'),
                      Text(
                          'o) critical security parameters used by the device can be communicated outside of the device;'),
                      Text(
                          'p) unused network or network accessible logical interfaces exist;'),
                      Text('q) debug interfaces exist on the device;'),
                      Text(
                          'r) debug interfaces that are physical ports exist on the device;'),
                      Text(
                          's) secure boot or other mechanism to detect unauthorized changes to IoT device software are supported by the device;'),
                      Text(
                          't) the consumer IoT device sends personal data to associated services;'),
                      Text(
                          'u) the consumer IoT device sends sensitive personal data to associated services;'),
                      Text(
                          'v) the consumer IoT device includes external sensing capabilities;'),
                      Text(
                          'w) telemetry data can be collected from consumer IoT devices and products;'),
                      Text(
                          'x) personal data can be stored by an associated service;'),
                      Text(
                          'y) the consumer IoT device processes personal data on the basis of consumers\' consent;'),
                      Text(
                          'z) the consumer IoT device processes personal data;'),
                      Text(
                          'aa) capabilities to collect data from consumer IoT devices or to processed data on the consumer IoT device, whose purpose is solely to compute an aggregate result. '),
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
                      child:
                          Text(AppLocalizations.of(context)!.generatePdfButton),
                    ),
                    const SizedBox(width: 20.0), // Space between buttons
                    ElevatedButton(
                      onPressed:
                          _createShareLink, // Call the placeholder function
                      child:
                          Text(AppLocalizations.of(context)!.shareLinkButton),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget to build the language selection dropdown
  Widget _buildLanguageDropdown(BuildContext context) {
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
          final langName = locale.languageCode == 'en'
              ? AppLocalizations.of(context)!.langEnglish
              : AppLocalizations.of(context)!
                  .langItalian; // Add more checks if you support more languages
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
        flex: text.contains(AppLocalizations.of(context)!.provisionNameHeader)
            ? 3
            : text.contains(AppLocalizations.of(context)!.notesHeader)
                ? 2
                : text.contains(AppLocalizations.of(context)!.statusHeader)
                    ? 1
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
                  items: const [
                    DropdownMenuItem(value: 'na', child: Text('N/A')),
                    DropdownMenuItem(value: 'yes', child: Text('Yes')),
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
                  items: const [
                    DropdownMenuItem(value: 'na', child: Text('N/A')),
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
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
                  items: const [
                    DropdownMenuItem(value: 'na', child: Text('N/A')),
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
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
                  items: const [
                    DropdownMenuItem(value: 'open', child: Text('Open')),
                    DropdownMenuItem(
                        value: 'mitigated', child: Text('Mitigated')),
                    DropdownMenuItem(
                        value: 'accepted', child: Text('Accepted')),
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
                  decoration: const InputDecoration(
                    hintText: 'Enter notes...',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
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
