import Foundation

enum IosNleErrorCode {
    static let engineNotInitialized = "ios_engine_not_initialized"
    static let sessionNotFound = "ios_session_not_found"
    static let invalidArguments = "ios_invalid_arguments"
    static let graphParseFailed = "ios_graph_parse_failed"
    static let graphValidationFailed = "ios_graph_validation_failed"
    static let unsupportedCommand = "ios_unsupported_command"
    static let commandFailed = "ios_command_failed"

    static let previewTextureNotFound = "ios_preview_texture_not_found"
    static let previewTextureCreateFailed = "ios_preview_texture_create_failed"

    static let mediaProbeFailed = "ios_media_probe_failed"

    static let proxyNotImplemented = "ios_proxy_not_implemented_v1"
    static let exportNotImplemented = "ios_export_not_implemented_v1"
}
