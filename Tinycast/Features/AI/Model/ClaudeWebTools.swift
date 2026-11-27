import Foundation

/// Claude's own web tools: the CLI's `WebSearch` and `WebFetch`, and the API's server-side pair.
enum ClaudeWebTools {
    static let cliSearch = "WebSearch"
    static let cliFetch = "WebFetch"
    static let apiSearch = "web_search"
    static let apiFetch = "web_fetch"

    static var origin: String { String(localized: "Web") }

    /// The API's oldest versions: the later ones run code to filter results, which nothing reads.
    static var serverTools: [[String: Any]] {
        [
            ["type": "web_search_20250305", "name": apiSearch, "max_uses": 5],
            [
                "type": "web_fetch_20250910", "name": apiFetch, "max_uses": 5,
                "max_content_tokens": 25_000
            ]
        ]
    }

    private static let cliTools = [cliSearch, cliFetch].joined(separator: ",")

    /// `--tools` names the built-ins a turn has, and an empty value is none of them.
    static func builtIns(offered: Bool) -> String { offered ? cliTools : "" }

    /// A headless turn has nobody to ask, so the reader's Web search switch is the consent.
    static func arguments(rounds: Int?, withServers: Bool) -> [String] {
        var result = ["--allowedTools", cliTools]
        guard !withServers else { return result }
        // `dontAsk` refuses what is not listed, where a prompt would wait for good.
        result += ["--permission-mode", "dontAsk"]
        if let rounds { result += ["--max-turns", "\(rounds)"] }
        return result
    }

    /// A page is named by host and path: the whole address can be a screenful of tracking.
    static func fetchTitle(_ address: String?) -> String {
        let address = address?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard let url = URL(string: address), let host = url.host() else {
            return AIToolServerRow.label(address)
        }
        let path = url.path()
        return AIToolServerRow.label(path == "/" ? host : host + path)
    }
}
