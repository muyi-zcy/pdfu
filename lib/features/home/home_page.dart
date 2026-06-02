import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_branding.dart';
import '../../core/models/pdf_feature.dart';
import '../../core/settings/app_scope.dart';
import '../docs/development_guide_page.dart';
import '../docs/user_guide_page.dart';
import '../settings/settings_page.dart';
import '../workspace/workspace_page.dart';
import 'widgets/feature_menu_item.dart';
import 'widgets/home_records_panel.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _openFeature(BuildContext context, PdfFeature feature) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => WorkspacePage(feature: feature),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final useSideBySide = width >= 760;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      useSideBySide ? 36 : 24,
                      24,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HomeHeader(colorScheme: colorScheme, theme: theme),
                        SizedBox(height: useSideBySide ? 32 : 24),
                        if (useSideBySide)
                          _SideBySideBody(onOpenFeature: _openFeature)
                        else
                          _StackedBody(onOpenFeature: _openFeature),
                      ],
                    ),
                  ),
                ),
                if (!useSideBySide)
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.colorScheme,
    required this.theme,
  });

  final ColorScheme colorScheme;
  final ThemeData theme;

  Future<void> _openWeixinArticle(BuildContext context) async {
    final uri = Uri.parse(kWeixinArticleUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法打开链接')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Image.asset(
            kAppLogoAsset,
            width: 36,
            height: 36,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          kAppName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        _DocLinkButton(
          icon: Icons.article_outlined,
          label: '有点草率杂货铺出品',
          onTap: () => _openWeixinArticle(context),
        ),
        const SizedBox(width: 4),
        _DocLinkButton(
          icon: Icons.menu_book_outlined,
          label: '使用说明',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const UserGuidePage(),
            ),
          ),
        ),
        const SizedBox(width: 4),
        _DocLinkButton(
          icon: Icons.code_outlined,
          label: '开发说明',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const DevelopmentGuidePage(),
            ),
          ),
        ),
        const SizedBox(width: 4),
        _DocLinkButton(
          icon: Icons.settings_outlined,
          label: '设置',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const SettingsPage(),
            ),
          ),
        ),
      ],
    );
  }
}

class _SideBySideBody extends StatelessWidget {
  const _SideBySideBody({required this.onOpenFeature});

  final void Function(BuildContext context, PdfFeature feature) onOpenFeature;

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.maybeOf(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: _FeatureMenuList(onOpenFeature: onOpenFeature),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 4,
          child: HomeRecordsPanel(
            history: settings?.history ?? const [],
            exportRecords: settings?.exportRecords ?? const [],
            onRemoveHistory: settings?.removeHistoryEntry ?? (_) {},
            onRemoveExport: settings?.removeExportRecord ?? (_) {},
          ),
        ),
      ],
    );
  }
}

class _StackedBody extends StatelessWidget {
  const _StackedBody({required this.onOpenFeature});

  final void Function(BuildContext context, PdfFeature feature) onOpenFeature;

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.maybeOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FeatureMenuList(onOpenFeature: onOpenFeature),
        const SizedBox(height: 24),
        HomeRecordsPanel(
          history: settings?.history ?? const [],
          exportRecords: settings?.exportRecords ?? const [],
          onRemoveHistory: settings?.removeHistoryEntry ?? (_) {},
          onRemoveExport: settings?.removeExportRecord ?? (_) {},
        ),
      ],
    );
  }
}

class _FeatureMenuList extends StatelessWidget {
  const _FeatureMenuList({required this.onOpenFeature});

  final void Function(BuildContext context, PdfFeature feature) onOpenFeature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '功能',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '本地处理，文件不上传',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...pdfFeatures.map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FeatureMenuItem(
              feature: feature,
              onTap: () => onOpenFeature(context, feature),
            ),
          ),
        ),
      ],
    );
  }
}

class _DocLinkButton extends StatelessWidget {
  const _DocLinkButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
