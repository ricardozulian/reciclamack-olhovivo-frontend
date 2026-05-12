import 'package:flutter/material.dart';

/// ReciclaMack Design Tokens — Dark Theme
/// Matches the reciclamack.com website (May 2026)
class ReciclaColors {
  // ── Primary — Emerald Green ───────────────────────────────
  static const Color primary = Color(0xFF10B981);
  static const Color primaryLight = Color(0xFF34D399);
  static const Color primaryDark = Color(0xFF059669);
  static const Color primarySurface = Color(0x1A10B981); // 10% opacity
  static const Color primaryBorder = Color(0x4010B981); // 25% opacity

  // ── Mackenzie Institutional (secondary, logo crest only) ──
  static const Color mackenzieRed = Color(0xFFEB0029);

  // ── Background Scale (dark theme) ─────────────────────────
  static const Color bgDeep = Color(0xFF070B0F);
  static const Color bg = Color(0xFF0D1117);
  static const Color bgElevated = Color(0xFF131A24);
  static const Color bgCard = Color(0xFF162032);
  static const Color bgCardHover = Color(0xFF1C2840);
  static const Color bgInput = Color(0xFF0F1620);

  // ── Foreground / Text ─────────────────────────────────────
  static const Color fg1 = Color(0xFFF0F6FC);
  static const Color fg2 = Color(0xFF8B949E);
  static const Color fg3 = Color(0xFF6E7681);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ── Borders & Dividers ────────────────────────────────────
  static const Color border = Color(0x14F0F6FC); // 8% opacity
  static const Color borderEmphasis = Color(0x29F0F6FC); // 16% opacity
  static const Color divider = Color(0x0FF0F6FC); // 6% opacity

  // ── Category / Pillar Colors ──────────────────────────────
  static const Color catImpact = Color(0xFFEF4444);
  static const Color catLogistics = Color(0xFFF59E0B);
  static const Color catInnovate = Color(0xFFEAB308);
  static const Color catTech = Color(0xFF8B5CF6);
  static const Color catEnterprise = Color(0xFF10B981);
  static const Color catPolicy = Color(0xFF3B82F6);

  // Category surfaces (12% opacity)
  static const Color catImpactSurface = Color(0x1FEF4444);
  static const Color catLogisticsSurface = Color(0x1FF59E0B);
  static const Color catInnovateSurface = Color(0x1FEAB308);
  static const Color catTechSurface = Color(0x1F8B5CF6);
  static const Color catEnterpriseSurface = Color(0x1F10B981);
  static const Color catPolicySurface = Color(0x1F3B82F6);

  // ── Semantic / State Colors ───────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color errorSurface = Color(0x1FEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0x1FF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color successSurface = Color(0x1F10B981);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoSurface = Color(0x1F3B82F6);
}

class ReciclaSpacing {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;

  /// Main content max width
  static const double contentMaxWidth = 1080;

  /// Nav bar height
  static const double navHeight = 64;

  /// Vertical section padding
  static const double sectionPadding = 48;
}

class ReciclaRadii {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 100;
}
