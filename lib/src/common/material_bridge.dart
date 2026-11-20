import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

/// Glue for the move from `package:flutter/material.dart` to
/// `package:material_ui`.
///
/// The two are separate class hierarchies, not one re-exporting the other: a
/// `Theme` from one is invisible to a `Theme.of` from the other, and the same
/// goes for `MaterialLocalizations`. This app and its own packages are on
/// material_ui; a handful of third-party packages (image loading, routing,
/// localisation, hooks) still build with the old one.
///
/// Delete this file, and its two call sites per app, once
/// `flutter analyze` on the dependency tree stops finding
/// `package:flutter/material.dart`.

/// easy_localization's delegates carry the OLD Material strings; material_ui
/// widgets ask for their own. Without the second set every built-in label —
/// the text-selection menu, dialog buttons, tooltips — falls back to English
/// under a Chinese interface.
List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates(
  BuildContext context,
) => [
  ...context.localizationDelegates,
  ...GlobalMaterialLocalizations.delegates,
];

/// Hands this app's theme and localisations to widgets from packages that
/// have not migrated. Goes in `MaterialApp.builder`, which is the first place
/// below the app's own `Theme`.
Widget legacyMaterialBridge(Widget child) =>
    // The bridge is born deprecated, on purpose: it is a migration aid.
    // ignore: deprecated_member_use
    MaterialUiCompatibilityBridge(child: child);
