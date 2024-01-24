//
//  LanguageView.swift
//  BPCureX
//
//  Created by yangjian on 2023/12/15.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct LanguageReducer: Reducer {
    struct State: Equatable {
        @FileHelper(.language, defaultValue: .default)
        var item: Item
        let items: [Item] = Item.allCases
    }
    enum Action: Equatable {
        case pop
        case itemDidSelected(State.Item)
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            if case let .itemDidSelected(item) = action {
                state.item = item
                return .run { send in
                    await send(.pop)
                }
            }
            return .none
        }
    }
}

extension Notification.Name {
    static let updateLanguage = Notification.Name(rawValue: "update.language")
}

extension LanguageReducer.State {
    enum Item: CaseIterable, Codable {
        case en, pt, fr, es, de, ar
        static let `default` = Locale.current.getItem()
        var locale: Locale {
            Locale(identifier: self.id)
        }
        var id: String {
            switch self {
            case .en:
                return "en_001@rg=vuzzzz"
            case .ar:
                return "ar_VU"
            case .pt:
                return "pt_PT@rg=vuzzzz"
            case .fr:
                return "fr_VU"
            case .es:
                return "es_VU"
            case .de:
                return "de_VU"
            }
        }
        var title: String {
            switch self {
            case .en:
                return "English"
            case .pt:
                return "Portuguese"
            case .fr:
                return "French"
            case .es:
                return "Spanish"
            case .de:
                return "German"
            case .ar:
                return "Arabic"
            }
        }
    }
}

extension Locale {
    func getItem() -> LanguageReducer.State.Item {
        LanguageReducer.State.Item.allCases.filter { item in
            item.id == self.identifier
        }.first ?? .en
    }
}

struct LanguageView: View {
    let store: StoreOf<LanguageReducer>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                ForEach(viewStore.items.indices, id:\.self) { index in
                    let item = viewStore.items[index]
                    let isSelected = item == viewStore.item
                    Button(action: {
                        viewStore.send(.itemDidSelected(item))
                    }, label: {
                            HStack{
                                Text(LocalizedStringKey(item.title)).foregroundStyle(isSelected ? Color("#5874FF") : Color("#6C729D"))
                                Spacer()
                                Image( isSelected ? "language_selected" : "language_unselected")
                            }
                    }).padding(.horizontal, 14).padding(.vertical, 12)
                }
                Spacer()
            }.background(Color("#ECF1FF")).back(LocalizedStringKey(ProfileReducer.State.Item.language.title)) {
                viewStore.send(.pop)
            }
        }
    }
}
