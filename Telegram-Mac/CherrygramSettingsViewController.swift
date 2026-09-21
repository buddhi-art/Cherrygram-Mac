//
//  CherrygramSettingsViewController.swift
//  TelegramMac
//

import Cocoa
import TGUIKit
import TelegramCore
import InAppSettings
import SwiftSignalKit
import Postbox
import Security

class CherrygramConfiguration {
    static let shared = CherrygramConfiguration()
    
    private let defaults = UserDefaults.standard
    
    let statePromise = ValuePromise<Int>(0, ignoreRepeated: true)
    private var stateCounter: Int = 0
    
    private func notifyUpdate() {
        stateCounter += 1
        statePromise.set(stateCounter)
    }
    
    private struct Keys {
        static let geminiEnabled = "cg_gemini_enabled"
        static let geminiApiKey = "cg_gemini_api_key"
        static let windowBlur = "cg_window_blur"
        static let donationsEnabled = "cg_donations_enabled"
        static let translatorEnabled = "cg_translator_enabled"
    }
    
    var isGeminiEnabled: Bool {
        get { return defaults.object(forKey: Keys.geminiEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.geminiEnabled); notifyUpdate() }
    }
    
    var geminiApiKey: String {
        get {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: Keys.geminiApiKey,
                kSecReturnData as String: kCFBooleanTrue!,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]
            var item: CFTypeRef?
            if SecItemCopyMatching(query as CFDictionary, &item) == noErr,
               let data = item as? Data,
               let key = String(data: data, encoding: .utf8) {
                return key
            }
            return ""
        }
        set {
            guard let data = newValue.data(using: .utf8) else { return }
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: Keys.geminiApiKey
            ]
            var status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
            if status == errSecItemNotFound {
                var newQuery = query
                newQuery[kSecValueData as String] = data
                status = SecItemAdd(newQuery as CFDictionary, nil)
            }
        }
    }
    
    var isWindowBlurEnabled: Bool {
        get { return defaults.object(forKey: Keys.windowBlur) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Keys.windowBlur); notifyUpdate() }
    }
    
    var isDonationsEnabled: Bool {
        get { return defaults.object(forKey: Keys.donationsEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.donationsEnabled); notifyUpdate() }
    }
    
    var enableTranslator: Bool {
        get { return defaults.object(forKey: Keys.translatorEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.translatorEnabled); notifyUpdate() }
    }
}

private enum CherrygramSettingsEntry: Comparable, Identifiable, Equatable {
    case section(sectionId: Int)
    case header(sectionId: Int, text: String)
    case gemini(sectionId: Int, enabled: Bool, viewType: GeneralViewType)
    case apiInput(sectionId: Int, text: String, viewType: GeneralViewType)
    case translator(sectionId: Int, enabled: Bool, viewType: GeneralViewType)
    case windowBlur(sectionId: Int, enabled: Bool, viewType: GeneralViewType)
    case donations(sectionId: Int, enabled: Bool, viewType: GeneralViewType)
    
    var stableId: AnyHashable {
        return AnyHashable(index)
    }
    
    var index: Int {
        switch self {
        case let .section(sectionId): return (sectionId * 1000)
        case let .header(sectionId, _): return (sectionId * 1000) + 1
        case let .gemini(sectionId, _, _): return (sectionId * 1000) + 2
        case let .apiInput(sectionId, _, _): return (sectionId * 1000) + 3
        case let .translator(sectionId, _, _): return (sectionId * 1000) + 4
        case let .windowBlur(sectionId, _, _): return (sectionId * 1000) + 5
        case let .donations(sectionId, _, _): return (sectionId * 1000) + 6
        }
    }
    
    static func <(lhs: CherrygramSettingsEntry, rhs: CherrygramSettingsEntry) -> Bool {
        return lhs.index < rhs.index
    }
    
    func item(context: AccountContext, initialSize: NSSize) -> TableRowItem {
        switch self {
        case let .section(sectionId):
            return GeneralRowItem(initialSize, height: 30, stableId: stableId, viewType: .separator)
        case let .header(_, text):
            return GeneralTextRowItem(initialSize, stableId: stableId, text: text, viewType: .textTopItem)
        case let .gemini(_, enabled, viewType):
            return GeneralInteractedRowItem(initialSize, stableId: stableId, name: "Enable Gemini AI", type: .switchable(enabled), viewType: viewType, action: {
                CherrygramConfiguration.shared.isGeminiEnabled = !enabled
            })
        case let .apiInput(_, text, viewType):
            return InputDataRowItem(initialSize, stableId: stableId, mode: .plain, error: nil, viewType: viewType, currentText: text, placeholder: nil, inputPlaceholder: "Gemini API Key", filter: { $0 }, updated: { text in
                CherrygramConfiguration.shared.geminiApiKey = text
            }, limit: 150)
        case let .windowBlur(_, enabled, viewType):
            return GeneralInteractedRowItem(initialSize, stableId: stableId, name: "Window Blur Effect", type: .switchable(enabled), viewType: viewType, action: {
                CherrygramConfiguration.shared.isWindowBlurEnabled = !enabled
            })
        case let .donations(_, enabled, viewType):
            return GeneralInteractedRowItem(initialSize, stableId: stableId, name: "Enable Donations Manager", type: .switchable(enabled), viewType: viewType, action: {
                CherrygramConfiguration.shared.isDonationsEnabled = !enabled
            })
        case let .translator(_, enabled, viewType):
            return GeneralInteractedRowItem(initialSize, stableId: stableId, name: "Enable Built-in Translator", type: .switchable(enabled), viewType: viewType, action: {
                CherrygramConfiguration.shared.enableTranslator = !enabled
            })
        }
    }
}

private func prepareEntries(left: [CherrygramSettingsEntry], right: [CherrygramSettingsEntry], initialSize: NSSize, context: AccountContext) -> TableUpdateTransition {
    let (removed, inserted, updated) = proccessEntriesWithoutReverse(left, right: right) { entry -> TableRowItem in
        return entry.item(context: context, initialSize: initialSize)
    }
    return TableUpdateTransition(deleted: removed, inserted: inserted, updated: updated, animated: true)
}

class CherrygramSettingsViewController: TableViewController {
    private let disposable = MetaDisposable()
    
    override init(_ context: AccountContext) {
        super.init(context)
        bar = .init(height: 0)
    }
    
    deinit {
        disposable.dispose()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.readyOnce()
        
        let initialSize = self.bounds.size
        let context = self.context
        
        let previous = Atomic<[CherrygramSettingsEntry]>(value: [])
        
        let signal = CherrygramConfiguration.shared.statePromise.get() 
            |> map { _ -> [CherrygramSettingsEntry] in
                var entries: [CherrygramSettingsEntry] = []
                var sectionId = 1
                
                entries.append(.section(sectionId: sectionId))
                entries.append(.header(sectionId: sectionId, text: "AI & TRANSLATOR"))
                entries.append(.gemini(sectionId: sectionId, enabled: CherrygramConfiguration.shared.isGeminiEnabled, viewType: .firstItem))
                entries.append(.apiInput(sectionId: sectionId, text: CherrygramConfiguration.shared.geminiApiKey, viewType: .innerItem))
                entries.append(.translator(sectionId: sectionId, enabled: CherrygramConfiguration.shared.enableTranslator, viewType: .lastItem))
                
                sectionId += 1
                entries.append(.section(sectionId: sectionId))
                entries.append(.header(sectionId: sectionId, text: "CUSTOMIZATION"))
                entries.append(.windowBlur(sectionId: sectionId, enabled: CherrygramConfiguration.shared.isWindowBlurEnabled, viewType: .singleItem))
                
                sectionId += 1
                entries.append(.section(sectionId: sectionId))
                entries.append(.header(sectionId: sectionId, text: "MONETIZATION"))
                entries.append(.donations(sectionId: sectionId, enabled: CherrygramConfiguration.shared.isDonationsEnabled, viewType: .singleItem))
                
                entries.append(.section(sectionId: sectionId + 1))
                return entries
            }
            |> deliverOnMainQueue
            
        disposable.set(signal.start(next: { [weak self] entries in
            guard let strongSelf = self else { return }
            let prev = previous.swap(entries)
            let transition = prepareEntries(left: prev, right: entries, initialSize: initialSize, context: context)
            strongSelf.genericView.merge(with: transition)
            strongSelf.readyOnce()
        }))
    }
}
