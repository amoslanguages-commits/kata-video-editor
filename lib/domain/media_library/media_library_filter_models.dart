import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';

class NleMediaLibraryFilter {
  final String query;
  final String? binId;
  final Set<NleMediaAssetType> types;
  final bool showMissingOnly;
  final bool showUsedOnly;
  final bool showUnusedOnly;
  final NleMediaSortMode sortMode;
  final NleMediaViewMode viewMode;

  const NleMediaLibraryFilter({
    required this.query,
    this.binId,
    required this.types,
    required this.showMissingOnly,
    required this.showUsedOnly,
    required this.showUnusedOnly,
    required this.sortMode,
    required this.viewMode,
  });

  const NleMediaLibraryFilter.defaultFilter()
      : query = '',
        binId = null,
        types = const {},
        showMissingOnly = false,
        showUsedOnly = false,
        showUnusedOnly = false,
        sortMode = NleMediaSortMode.newest,
        viewMode = NleMediaViewMode.grid;

  NleMediaLibraryFilter copyWith({
    String? query,
    String? binId,
    Set<NleMediaAssetType>? types,
    bool? showMissingOnly,
    bool? showUsedOnly,
    bool? showUnusedOnly,
    NleMediaSortMode? sortMode,
    NleMediaViewMode? viewMode,
    bool clearBin = false,
  }) {
    return NleMediaLibraryFilter(
      query: query ?? this.query,
      binId: clearBin ? null : binId ?? this.binId,
      types: types ?? this.types,
      showMissingOnly: showMissingOnly ?? this.showMissingOnly,
      showUsedOnly: showUsedOnly ?? this.showUsedOnly,
      showUnusedOnly: showUnusedOnly ?? this.showUnusedOnly,
      sortMode: sortMode ?? this.sortMode,
      viewMode: viewMode ?? this.viewMode,
    );
  }
}
