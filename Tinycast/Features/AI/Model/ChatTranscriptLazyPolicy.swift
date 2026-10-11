import Foundation

/// Which part of a long transcript is built up front; older messages wait until they are scrolled to.
enum ChatTranscriptLazyPolicy {

    /// Cost units built up front: about a screenful of the newest messages.
    static let eagerBudget = 40

    /// What a message costs to build, as a count of rows: a search or tool is one, prose a few.
    static func weight(of message: ChatMessage) -> Int {
        4 + message.searches.count * 2 + message.reasoning.count + message.toolUses.count
            + message.images.count * 4 + message.documents.count + message.text.utf8.count / 1200
    }

    /// The first message built up front; 0 when the whole chat is cheap, so most chats never go lazy.
    static func eagerStart(in messages: [ChatMessage]) -> Int {
        let total = messages.reduce(0) { $0 + weight(of: $1) }
        guard total > eagerBudget * 3 else { return 0 }
        var index = messages.count
        var spent = 0
        while index > 0, spent < eagerBudget {
            index -= 1
            spent += weight(of: messages[index])
        }
        return index
    }
}
