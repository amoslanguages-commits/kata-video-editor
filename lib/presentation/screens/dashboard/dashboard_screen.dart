import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/utils/time_utils.dart';
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/screens/editor/editor_screen.dart';
import 'package:nle_editor/presentation/screens/projects/create_project_flow_screen.dart';
import 'package:nle_editor/presentation/screens/settings/settings_screen.dart';
import 'package:nle_editor/presentation/widgets/recovery/recovery_badge.dart';
import 'package:shimmer/shimmer.dart';

import 'package:nle_editor/core/copy/app_copy.dart';
import 'package:nle_editor/core/navigation/premium_page_route.dart';
import 'package:nle_editor/presentation/providers/polish_providers.dart';
import 'package:nle_editor/presentation/widgets/polish/premium_empty_state.dart';
import 'package:nle_editor/presentation/widgets/premium/premium_bounce_button.dart';


class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // On first launch, mark any jobs that were still "running" from a previous
    // session as interrupted/failed. Does not notify the user with a banner —
    // they'll see the badge on affected project cards via the error log.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(interruptedJobRecoveryServiceProvider)
          .markInterruptedJobs(notify: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectListProvider);


    return Scaffold(
      backgroundColor: AppTheme.editorBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Studio',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your projects',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        PremiumBounceButton(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.settings_rounded, color: AppTheme.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.accentGradientStart, AppTheme.accentGradientEnd],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.person, color: Colors.black, size: 22),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: PremiumBounceButton(
                  onTap: () => _showNewProject(context),
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.accentGradientStart, AppTheme.accentGradientEnd],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'New Project',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Projects',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
            ),
            
            projectsAsync.when(
              data: (projects) {
                if (projects.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _buildEmptyState(context),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final project = projects[index];
                        return _ProjectCard(project: project);
                      },
                      childCount: projects.length,
                    ),
                  ),
                );
              },
              loading: () => SliverToBoxAdapter(
                child: _buildShimmerGrid(),
              ),
              error: (err, stack) => SliverToBoxAdapter(
                child: Center(child: Text('Error: $err')),
              ),
            ),
            
            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ),
      ),
    );
  }
  
  void _showNewProject(BuildContext context) {
    ref.read(hapticServiceProvider).selection();
    Navigator.of(context).push(
      PremiumPageRoute(page: const CreateProjectFlowScreen()),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return PremiumEmptyState(
      icon: Icons.movie_creation_outlined,
      title: AppCopy.emptyProjectsTitle,
      message: AppCopy.emptyProjectsBody,
      actionLabel: 'New Project',
      actionIcon: Icons.add_rounded,
      onAction: () => _showNewProject(context),
    );
  }

  
  Widget _buildShimmerGrid() {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceDark,
      highlightColor: AppTheme.surfaceElevated,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: List.generate(4, (index) => Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
          )),
        ),
      ),
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  final Project project;
  
  const _ProjectCard({required this.project});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aspectRatio = _parseAspectRatio(project.aspectRatio);
    final recoveryAsync = ref.watch(recoverySnapshotInfoProvider(project.id));
    final hasRecovery = recoveryAsync.value?.hasRecovery ?? false;

    return PremiumBounceButton(
      onTap: () {
        ref.read(selectedProjectIdProvider.notifier).state = project.id;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EditorScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.borderRadiusMedium - 1),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: aspectRatio,
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceOverlay,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getIconForAspectRatio(project.aspectRatio),
                            color: AppTheme.textMuted.withValues(alpha: 0.5),
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    if (hasRecovery)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: RecoveryBadge(visible: true),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        project.aspectRatio,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: AppTheme.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${project.targetFrameRate}fps',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    TimeUtils.formatMicros(project.durationMicros),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  double _parseAspectRatio(String ratio) {
    switch (ratio) {
      case '9:16': return 9 / 16;
      case '1:1': return 1;
      case '4:5': return 4 / 5;
      case '21:9': return 21 / 9;
      case 'custom': return 16 / 9;
      default: return 16 / 9;
    }
  }
  
  IconData _getIconForAspectRatio(String ratio) {
    switch (ratio) {
      case '9:16': return Icons.smartphone;
      case '1:1': return Icons.crop_square;
      case '4:5': return Icons.crop_portrait;
      case '21:9': return Icons.movie;
      default: return Icons.movie_outlined;
    }
  }
}
