import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/motion_templates/motion_template_models.dart';
import 'package:nle_editor/domain/motion_templates/motion_template_value_models.dart';
import 'package:nle_editor/presentation/providers/motion_template_providers.dart';

class MotionTemplateBrowser extends ConsumerStatefulWidget {
  final ValueChanged<NleMotionTemplate> onTemplateSelected;

  const MotionTemplateBrowser({
    super.key,
    required this.onTemplateSelected,
  });

  @override
  ConsumerState<MotionTemplateBrowser> createState() => _MotionTemplateBrowserState();
}

class _MotionTemplateBrowserState extends ConsumerState<MotionTemplateBrowser> {
  String _activeTab = 'all'; // 'all', 'favorites', 'recents', or NleMotionTemplateCategory.name

  @override
  Widget build(BuildContext context) {
    final browserState = ref.watch(motionTemplateControllerProvider);
    final controller = ref.read(motionTemplateControllerProvider.notifier);

    if (browserState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final templates = _filterTemplates(browserState);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTabs(),
        const SizedBox(height: 12),
        Expanded(
          child: templates.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: PremiumSpacing.md),
                  itemCount: templates.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    final isFavorite = browserState.favorites.contains(template.id);

                    return _TemplateCard(
                      template: template,
                      isFavorite: isFavorite,
                      onTap: () {
                        controller.selectTemplate(template.id);
                        widget.onTemplateSelected(template);
                      },
                      onFavoriteToggle: () {
                        controller.toggleFavorite(template.id, !isFavorite);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<NleMotionTemplate> _filterTemplates(MotionTemplateBrowserState browserState) {
    final all = browserState.packs.expand((p) => p.templates).toList();

    if (_activeTab == 'all') {
      return all;
    } else if (_activeTab == 'favorites') {
      return all.where((t) => browserState.favorites.contains(t.id)).toList();
    } else if (_activeTab == 'recents') {
      return all.where((t) => browserState.recents.contains(t.id)).toList();
    } else {
      return all.where((t) {
        return t.categories.any((c) => c.name == _activeTab);
      }).toList();
    }
  }

  Widget _buildTabs() {
    final tabs = [
      {'id': 'all', 'label': 'All'},
      {'id': 'favorites', 'label': 'Favorites'},
      {'id': 'recents', 'label': 'Recents'},
      ...NleMotionTemplateCategory.values.map((c) => {
            'id': c.name,
            'label': _categoryLabel(c),
          }),
    ];

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: PremiumSpacing.md),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isActive = _activeTab == tab['id'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                tab['label']!,
                style: TextStyle(
                  color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              selected: isActive,
              selectedColor: AppTheme.accentPrimary,
              backgroundColor: const Color(0xFF0D1320),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PremiumRadius.md),
                side: BorderSide(
                  color: isActive ? AppTheme.accentPrimary : AppTheme.borderSubtle,
                ),
              ),
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _activeTab = tab['id']!;
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _activeTab == 'favorites' ? Icons.star_border : Icons.layers_clear_outlined,
            color: AppTheme.textMuted,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            _activeTab == 'favorites'
                ? 'No favorites marked yet'
                : _activeTab == 'recents'
                    ? 'No recently used templates'
                    : 'No templates available in this category',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(NleMotionTemplateCategory category) {
    switch (category) {
      case NleMotionTemplateCategory.titles:
        return 'Titles';
      case NleMotionTemplateCategory.lowerThirds:
        return 'Lower Thirds';
      case NleMotionTemplateCategory.captions:
        return 'Captions';
      case NleMotionTemplateCategory.callouts:
        return 'Callouts';
      case NleMotionTemplateCategory.social:
        return 'Social';
      case NleMotionTemplateCategory.business:
        return 'Business';
      case NleMotionTemplateCategory.cinematic:
        return 'Cinematic';
      case NleMotionTemplateCategory.stickers:
        return 'Stickers';
      case NleMotionTemplateCategory.arrows:
        return 'Arrows';
      case NleMotionTemplateCategory.highlights:
        return 'Highlights';
      case NleMotionTemplateCategory.news:
        return 'News';
      case NleMotionTemplateCategory.minimal:
        return 'Minimal';
    }
  }
}

class _TemplateCard extends StatelessWidget {
  final NleMotionTemplate template;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const _TemplateCard({
    required this.template,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0D1320),
      borderRadius: BorderRadius.circular(PremiumRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PremiumRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PremiumRadius.lg),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: Icon(
                          _categoryIcon(template.categories.first),
                          color: AppTheme.accentPrimary,
                          size: 32,
                        ),
                      ),
                    ),
                    Text(
                      template.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      template.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite ? Colors.amber : AppTheme.textMuted,
                    size: 16,
                  ),
                  onPressed: onFavoriteToggle,
                ),
              ),
              if (template.isPremium)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(PremiumRadius.sm),
                      border: Border.all(color: AppTheme.accentPrimary.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      template.access.name.toUpperCase(),
                      style: TextStyle(
                        color: AppTheme.accentPrimary,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(NleMotionTemplateCategory category) {
    switch (category) {
      case NleMotionTemplateCategory.titles:
        return Icons.title_rounded;
      case NleMotionTemplateCategory.lowerThirds:
        return Icons.subtitles_rounded;
      case NleMotionTemplateCategory.captions:
        return Icons.closed_caption_rounded;
      case NleMotionTemplateCategory.callouts:
        return Icons.chat_bubble_outline_rounded;
      case NleMotionTemplateCategory.social:
        return Icons.share_rounded;
      case NleMotionTemplateCategory.business:
        return Icons.business_center_rounded;
      case NleMotionTemplateCategory.cinematic:
        return Icons.movie_creation_rounded;
      case NleMotionTemplateCategory.stickers:
        return Icons.emoji_emotions_rounded;
      case NleMotionTemplateCategory.arrows:
        return Icons.arrow_forward_rounded;
      case NleMotionTemplateCategory.highlights:
        return Icons.highlight_rounded;
      case NleMotionTemplateCategory.news:
        return Icons.newspaper_rounded;
      case NleMotionTemplateCategory.minimal:
        return Icons.crop_square_rounded;
    }
  }
}
