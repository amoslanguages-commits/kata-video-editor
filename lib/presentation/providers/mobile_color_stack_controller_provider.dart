import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/color_nodes/color_node_models.dart';
import 'package:nle_editor/presentation/controllers/mobile_color_stack_controller.dart';
import 'package:nle_editor/presentation/providers/color_node_graph_providers.dart';

class MobileColorStackOwner {
  final String ownerId;
  final NleColorNodeScope scope;

  const MobileColorStackOwner({
    required this.ownerId,
    required this.scope,
  });

  @override
  bool operator ==(Object other) {
    return other is MobileColorStackOwner &&
        other.ownerId == ownerId &&
        other.scope == scope;
  }

  @override
  int get hashCode => Object.hash(ownerId, scope);
}

final mobileColorStackControllerProvider =
    StateNotifierProvider.family<
        MobileColorStackController,
        MobileColorStackState,
        MobileColorStackOwner>((ref, owner) {
  return MobileColorStackController(
    ownerId: owner.ownerId,
    scope: owner.scope,
    repository: ref.watch(colorNodeGraphRepositoryProvider),
  );
});
