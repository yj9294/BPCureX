//
//  ContentView.swift
//  BPCureX
//
//  Created by yangjian on 2023/12/12.
//

import SwiftUI
import ComposableArchitecture

struct ContentReducer: Reducer {
    struct State: Equatable {
        var item: Item = .launching
        var launch: LaunchReducer.State = .init()
        var home: HomeReducer.State = .init()
        
        @FileHelper(.language, defaultValue: .default)
        var language: LanguageReducer.State.Item
        
    }
    enum Action: Equatable {
        case launch(LaunchReducer.Action)
        case home(HomeReducer.Action)
        case itemDidSelected(Item)
        case language(LanguageReducer.State.Item)
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            if case .launch(.update) = action {
                state.item = state.launch.isLaunched ? .launched : .launching
            }
            if case let .itemDidSelected(item) =  action {
                state.item = item
            }
            
            if case let .language(item) = action {
                state.language = item
                let reminders = FileHelper.getObject([String].self, forKey: .reminder)
                reminders?.forEach({NotificationHelper.shared.appendReminder($0)})
            }
//            if case let .home(.profile(.path(.element(id: _, action: .language(.itemDidSelected(item)))))) = action {
//                state.language = item
//                let reminders = FileHelper.getObject([String].self, forKey: .reminder)
//                reminders?.forEach({NotificationHelper.shared.appendReminder($0)})
//            }
            return .none
        }
        Scope(state: \.launch, action: /Action.launch) {
            LaunchReducer()
        }
        Scope(state: \.home, action: /Action.home) {
            HomeReducer()
        }
    }
}

extension ContentReducer {
    enum Item {
        case launching, launched
    }
}


struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase
    let store: StoreOf<ContentReducer>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                switch viewStore.item {
                case .launching:
                    LaunchView(store: store.scope(state: \.launch, action: {.launch($0)}))
                case .launched:
                    HomeView(store: store.scope(state: \.home, action: {.home($0)}))
                }
            }.onChange(of: scenePhase) { state in
                switch state {
                case .active:
                    viewStore.send(.itemDidSelected(.launching))
                default:
                    break
                }
            }.environment(\.locale, viewStore.language.locale).onReceive(NotificationCenter.default.publisher(for: .updateLanguage), perform: { noti in
                if let language = noti.object as? LanguageReducer.State.Item {
                    viewStore.send(.language(language))
                }
            })
        }
    }
}
