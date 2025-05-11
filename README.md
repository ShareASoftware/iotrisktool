# ETSI EN 303 645 Threat Assessment Tool

## Project Objective

This Flutter application is designed to assist users in performing a threat assessment based on the **ETSI EN 303 645 v3.1.3 (2024-09)** standard for Consumer Internet of Things (IoT) security.

The tool allows users to:
*   Systematically go through the provisions outlined in the standard.
*   Assess the applicability of each provision to their specific IoT product or system.
*   Define the likelihood and impact of potential threats related to each provision.
*   Automatically calculate a risk score for each provision.
*   Track the status of each provision (e.g., Open, Mitigated, Accepted).
*   Add specific notes for each provision.
*   Generate a comprehensive PDF report of the assessment.
*   Use the application in multiple languages (currently English and Italian).

The primary goal is to provide a structured and user-friendly way to conduct and document an ETSI EN 303 645 security assessment.

## Features

*   **Interactive Assessment Table:** Lists all provisions from the standard, allowing direct input for applicability, likelihood, impact, and status.
*   **Dynamic Risk Calculation:** Automatically computes the risk score (Low, Medium, High) based on likelihood and impact.
*   **PDF Report Generation:** Creates a shareable PDF document summarizing the assessment, including the product name and all entered data.
*   **Localization:** Supports multiple languages (English and Italian implemented).
*   **Product Identification:** Allows users to specify the "Product Name / System Under Assessment" for the report.
*   **Notes per Provision:** Text field for detailed notes for each security provision.
*   **Status Tracking:** Dropdown to set the status of each provision (Open, Mitigated, Accepted).
*   **Responsive UI:** Designed to be usable on various screen sizes, leveraging Flutter's capabilities.

## Open Source & Collaboration

This ETSI EN 303 645 Threat Assessment Tool is an **open-source project**, and we warmly welcome contributions from the community! Our goal is to create a valuable, evolving tool for IoT security professionals and enthusiasts.

**Why Contribute?**
*   **Improve the Tool:** Help us enhance features, fix bugs, and keep the tool aligned with the latest standard revisions.
*   **Share Your Expertise:** Your insights into IoT security and the ETSI standard can greatly benefit others.
*   **Learn and Grow:** Contributing to open source is a fantastic way to learn new skills and collaborate with others.

**How to Contribute:**
*   **Report Issues:** Found a bug or have a suggestion? Please open an issue on our GitHub repository.
*   **Propose Enhancements:** Have an idea for a new feature or an improvement to an existing one? We'd love to hear it!
*   **Submit Pull Requests:** If you've made changes you'd like to share, please submit a pull request.

We believe in the power of collaborative development. Feel free to fork the repository, experiment, and propose improvements!

## Prerequisites

*   **Flutter SDK:** Ensure you have the Flutter SDK installed. You can find installation instructions on the [official Flutter website](https://flutter.dev/docs/get-started/install).
*   **Code Editor:** A code editor like Visual Studio Code (with Flutter and Dart extensions) or Android Studio.
*   **Web Browser:** For running the web version (e.g., Chrome, Edge).

## Setting up a Local Development Environment (Recommended)

To ensure consistency and avoid conflicts with other Flutter projects or global Flutter installations, it's highly recommended to use a Flutter Version Manager like [FVM](https://fvm.app/).

1.  **Install FVM:**
    If you don't have FVM installed, you can install it by running:
    ```bash
    dart pub global activate fvm
    ```
    Make sure that your Dart SDK's `bin` directory is in your system's PATH.

2.  **Configure FVM for the Project:**
    *   Navigate to the cloned project directory.
    *   This project might have a specific Flutter version defined in `.fvm/fvm_config.json` or you can infer a compatible version from the `environment: sdk:` constraint in `pubspec.yaml`.
    *   If a `.fvm/fvm_config.json` file exists, FVM will pick it up. You can install the version by running:
        ```bash
        fvm install
        ```
    *   If you need to set a specific version (e.g., based on `pubspec.yaml`):
        ```bash
        fvm use <flutter_version> # e.g., fvm use 3.19.0
        ```
    *   After this, all Flutter commands should be prefixed with `fvm` (e.g., `fvm flutter pub get` instead of `flutter pub get`).

## Setup & Build Instructions

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/<your-github-username>/<your-repo-name>.git
    cd <your-repo-name> # Or the specific project directory, e.g., iotrisktool
    ```
    Replace `<your-github-username>/<your-repo-name>.git` with the actual URL of your GitHub repository and `<your-repo-name>` with the directory name created by the clone.

2.  **Get Dependencies:**
    Open a terminal in the project root directory and run:
    ```bash
    fvm flutter pub get
    ```
    This command fetches all the necessary packages defined in `pubspec.yaml`.

3.  **Generate Localization Files:**
    The project uses `flutter_localizations`. If you modify any `.arb` files in `lib/l10n/` or add new languages, you need to regenerate the localization delegates:
    ```bash
    fvm flutter gen-l10n
    ```

4.  **Build the Application:**
    You can build the application for various platforms. Here's how for web:

    *   **For Web:**
        ```bash
        fvm flutter build web --release
        ```
        The build output will be located in the `build/web` directory. You might want to use `--base-href /your-repo-name/` if deploying to GitHub Pages in a subfolder. For general use, `--release` is good.

    *   **For Desktop (e.g., Windows - if enabled):**
        To enable desktop support (if not already done for your project):
        ```bash
        fvm flutter create . --platforms=windows,macos,linux # Or just the ones you need
        ```
        Then build:
        ```bash
        fvm flutter build windows --release
        ```
        The output will be in `build/windows/runner/Release/`.

## Run Instructions

*   **For Web (Development):**
    To run the app in a development environment (with hot reload):
    ```bash
    fvm flutter run -d chrome
    ```
    (Replace `chrome` with `edge` or another supported browser if preferred).

*   **For Web (Release - after building):**
    After running `flutter build web`, you need to serve the files from the `build/web` directory.
    1.  You can use a simple HTTP server. If you have Python installed:
        ```bash
        cd build/web
        python -m http.server 8000
        ```
        Then open `http://localhost:8000` in your browser.
    2.  Alternatively, use `dhttpd` (a simple Dart HTTP server):
        ```bash
        # Install dhttpd if you haven't already
        dart pub global activate dhttpd
        # Navigate to the build output directory
        cd build/web
        # Serve the content
        dhttpd --port 8080
        ```
        Then open `http://localhost:8080` in your browser.

*   **For Desktop (Development - e.g., Windows):**
    ```bash
    fvm flutter run -d windows
    ```

*   **For Desktop (Release - after building):**
    Navigate to the build output directory (e.g., `build/windows/runner/Release/`) and run the generated executable file (e.g., `iotrisktool.exe`).

## Localization

The application supports internationalization.
*   Localization strings are managed in `.arb` (Application Resource Bundle) files located in `lib/l10n/`.
    *   `app_en.arb` for English.
    *   `app_it.arb` for Italian.
*   **To add a new language (e.g., Spanish 'es'):**
    1.  Create a new file `lib/l10n/app_es.arb`.
    2.  Copy the content structure from `app_en.arb` into `app_es.arb` and translate the string values.
        ```json
        // Example app_es.arb
        {
            "@@locale": "es",
            "appTitle": "Herramienta de Evaluación de Amenazas ETSI",
            "productNameLabel": "Nombre del Producto",
            // ... other translations
        }
        ```
    3.  Add the new `Locale` to the `supportedLocales` list in `MaterialApp` in `lib/main.dart`:
        ```dart
        supportedLocales: const [
          Locale('en', ''), // English
          Locale('it', ''), // Italian
          Locale('es', ''), // Spanish
        ],
        ```
    4.  Update the `_buildLanguageDropdown` method in `_ThreatAssessmentPageState` in `lib/main.dart` to include the display name for the new language. You'll need to add a corresponding string in your `.arb` files (e.g., `langSpanish`).
        ```dart
        // In _buildLanguageDropdown:
        // ...
        final langName = locale.languageCode == 'en'
            ? AppLocalizations.of(context)!.langEnglish
            : locale.languageCode == 'it'
                ? AppLocalizations.of(context)!.langItalian
                : AppLocalizations.of(context)!.langSpanish; // Add this
        // ...

        // In app_en.arb:
        // "langSpanish": "Spanish",
        // In app_it.arb:
        // "langSpanish": "Spagnolo",
        // In app_es.arb:
        // "langSpanish": "Español",
        ```
    5.  Run the command to regenerate the localization files:
        ```bash
        fvm flutter gen-l10n
        ```
    6.  Restart your application to see the changes.

## Key Dependencies

*   `flutter/material.dart`: Core Flutter UI framework.
*   `pdf`: For generating PDF documents.
*   `printing`: For PDF previewing and sharing functionalities.
*   `flutter_localizations`: For internationalization and localization.
*   `flutter_gen`: Used by `flutter_localizations` for code generation.
*   `intl`: (Implicitly used by `flutter_localizations`) For internationalization utilities.

## Project Structure

*   `lib/main.dart`: Contains the main application logic, UI structure, data models, and PDF generation code.
*   `lib/l10n/`: Directory for localization (`.arb`) files.
*   `assets/`: (If you add assets like fonts or images)
    *   `assets/fonts/`: The `Inter` font family is referenced; ensure font files are placed here and declared in `pubspec.yaml` if custom fonts are bundled.
*   `pubspec.yaml`: Project metadata, dependencies, and asset declarations.

## Enhanced Version

For users looking for additional features, premium support, or a managed cloud version of this tool, an enhanced version is available at **www.iotrisktool.org** (Note: This is a fictional website for demonstration purposes).

---

This README should provide a good overview for anyone looking to understand, build, or contribute to your project.