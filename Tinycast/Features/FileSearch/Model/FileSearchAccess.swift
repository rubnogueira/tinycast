import Foundation

/// What the scopes ask macOS for, worked out from the roots and ignore patterns alone.
enum FileSearchAccess {
    /// Home-relative folders only Full Disk Access opens; there is no prompt for them.
    private static let homeFullDiskFolders = [
        ".Trash",
        "Library/Application Support/AddressBook",
        "Library/Application Support/CallHistoryDB",
        "Library/Application Support/CallHistoryTransactions",
        "Library/Application Support/FaceTime",
        "Library/Application Support/Knowledge",
        "Library/Application Support/MobileSync",
        "Library/Application Support/com.apple.TCC",
        "Library/Assistant/SiriVocabulary",
        "Library/Biome",
        "Library/Calendars",
        "Library/Cookies",
        "Library/Daemon Containers",
        "Library/DoNotDisturb",
        "Library/HomeKit",
        "Library/IdentityServices",
        "Library/Mail",
        "Library/Messages",
        "Library/Metadata/CoreSpotlight",
        "Library/PersonalizationPortrait",
        "Library/Reminders",
        "Library/Safari",
        "Library/Sharing",
        "Library/StatusKit",
        "Library/Suggestions",
        "Library/Trial"
    ]
    private static let systemFullDiskFolders = [
        "/Library/Application Support/Apple/ParentalControls",
        "/Library/Application Support/com.apple.TCC"
    ]
    /// macOS asks about each once, so a grant covers that folder and nothing else.
    private static let promptedHomeFolders = [
        "Desktop", "Documents", "Downloads", "Library/Mobile Documents/com~apple~CloudDocs"
    ]

    static func fullDiskFolders(homeDirectory: URL) -> [String] {
        homeFullDiskFolders.map { FileSearchScope.join(homeDirectory.path, $0) } + systemFullDiskFolders
    }

    /// A root needs it when a crawl from there would open one of those folders.
    static func rootsNeedingFullDiskAccess(_ policy: FileSearchPolicy) -> [String] {
        let folders = fullDiskFolders(homeDirectory: policy.homeDirectory)
        return policy.roots.filter { root in
            folders.contains { folder in
                FileSearchScope.contains(folder, root)
                    || (FileSearchScope.contains(root, folder)
                        && isReachable(folder, from: root, policy: policy))
            }
        }
    }

    /// The roots, plus each prompted folder a root would walk into: where a refusal can hide.
    static func foldersToProbe(_ policy: FileSearchPolicy) -> [String] {
        let prompted = promptedHomeFolders.map {
            FileSearchScope.join(policy.homeDirectory.path, $0)
        }
        let inside = prompted.filter { folder in
            policy.roots.contains { root in
                root != folder && FileSearchScope.contains(root, folder)
                    && isReachable(folder, from: root, policy: policy)
            }
        }
        return policy.roots + inside
    }

    /// The root itself is never matched by an ignore pattern, only what lies below it.
    private static func isReachable(
        _ folder: String, from root: String, policy: FileSearchPolicy
    ) -> Bool {
        var path = root
        for component in folder.dropFirst(root == "/" ? 1 : root.count + 1).split(separator: "/") {
            path = FileSearchScope.join(path, String(component))
            if policy.ignore.excludes(name: String(component), path: path) { return false }
        }
        return true
    }
}
