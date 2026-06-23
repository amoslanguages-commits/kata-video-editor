import 'package:flutter/material.dart';
import 'package:nle_editor/core/theme/app_theme.dart';

class MulticamGridView extends StatefulWidget {
  final String projectId;
  
  const MulticamGridView({super.key, required this.projectId});

  @override
  State<MulticamGridView> createState() => _MulticamGridViewState();
}

class _MulticamGridViewState extends State<MulticamGridView> {
  int _activeAngle = 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Header
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceDark,
              border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
            ),
            child: const Row(
              children: [
                Icon(Icons.videocam_rounded, color: AppTheme.textMuted, size: 16),
                SizedBox(width: 8),
                Text(
                  'MULTICAM ANGLES',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          
          // Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildAngleView(1)),
                        const SizedBox(width: 4),
                        Expanded(child: _buildAngleView(2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildAngleView(3)),
                        const SizedBox(width: 4),
                        Expanded(child: _buildAngleView(4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAngleView(int angleId) {
    final isActive = _activeAngle == angleId;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeAngle = angleId;
        });
        
        // In a real implementation, this would trigger a cut on the timeline
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cut to Angle $angleId recorded to timeline.'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.accentPrimary,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.editorBackground,
          border: Border.all(
            color: isActive ? Colors.redAccent : AppTheme.borderSubtle,
            width: isActive ? 2.0 : 1.0,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Placeholder for video frame
            const Center(
              child: Icon(Icons.movie_creation_outlined, color: Colors.white24, size: 48),
            ),
            
            // Camera Label
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? Colors.redAccent : Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'CAM $angleId',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
