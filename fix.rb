content = File.read("Telegram-Mac/BlockedPeersViewController.swift")
content = content.sub(/private enum BlockedPeerEntryStableId: Hashable \{[^{}]+\}[^{}]+\}/, "private enum BlockedPeerEntryStableId: Hashable {\n    case peer(PeerId)\n    case empty\n    case sectionId(Int32)\n}\n")
File.write("Telegram-Mac/BlockedPeersViewController.swift", content)
