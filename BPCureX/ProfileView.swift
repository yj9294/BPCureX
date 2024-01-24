//
//  ProfileView.swift
//  BPCureX
//
//  Created by yangjian on 2023/12/12.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct ProfileReducer: Reducer {
    struct State: Equatable {
        let items = Item.allCases
        var path: StackState<Path1.State> = .init()
    }
    enum Action: Equatable {
        case itemDidSelected(State.Item)
        case path(StackAction<Path1.State, Path1.Action>)
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            if case let .itemDidSelected(item) = action {
                state.pushView(item)
            }
            if case .path(.element(id: _, action: .reminder(.pop))) = action {
                state.popView()
            }
            if case .path(.element(id: _, action: .privacy(.pop))) = action {
                state.popView()
            }
            if case let .path(.element(id: id, action: .language(.pop))) = action {
                if case let .language(languageState) = state.path[id: id] {
                    let item = languageState.item
                    state.popView()
                    NotificationCenter.default.post(name: .updateLanguage, object: item)
                }
            }
            return .none
        }.forEach(\.path, action: /Action.path) {
            Path1()
        }
    }
    struct Path1: Reducer {
        enum State: Equatable {
            case reminder(ReminderReducer.State = .init())
            case privacy(PrivacyReducer.State = .init())
            case language(LanguageReducer.State = .init())
        }
        enum Action: Equatable {
            case reminder(ReminderReducer.Action)
            case privacy(PrivacyReducer.Action)
            case language(LanguageReducer.Action)
            
        }
        var body: some Reducer<State, Action> {
            Reduce{ state, action in
                return .none
            }
            Scope(state: /State.reminder, action: /Action.reminder) {
                ReminderReducer()
            }
            Scope(state: /State.privacy, action: /Action.privacy) {
                PrivacyReducer()
            }
            Scope(state: /State.language, action: /Action.language) {
                LanguageReducer()
            }
        }
    }
}

extension ProfileReducer.State {
    enum Item: String, CaseIterable {
        case reminder, privacy, language, rate
        var title: String {
            switch self {
            case .reminder:
                return "Daily reminder"
            case .privacy:
                return "Privacy policy"
            case .language:
                return "Language"
            case .rate:
                return "Contact us"
            }
        }
        var icon: String{
            return "profile_\(self.rawValue)"
        }
    }
    
    mutating func pushView(_ item: Item) {
        switch item {
        case .reminder:
            path.append(.reminder())
        case .privacy:
            path.append(.privacy())
        case .language:
            path.append(.language())
        case .rate:
            let AppUrl = "https://itunes.apple.com/cn/app/id6476556887"
            OpenURLAction { URL in
                .systemAction(URL)
            }.callAsFunction(URL(string: AppUrl)!)
        }
    }
    
    mutating func popView() {
        path.removeLast()
    }
}

struct ProfileView: View {
    let store: StoreOf<ProfileReducer>
    var body: some View {
        NavigationStackStore(store.scope(state: \.path, action: {.path($0)})) {
            RootView(store: store)
        } destination: {
            switch $0 {
            case .reminder:
                CaseLet(/ProfileReducer.Path1.State.reminder, action: ProfileReducer.Path1.Action.reminder, then: ReminderView.init(store:))
            case .privacy:
                CaseLet(/ProfileReducer.Path1.State.privacy, action: ProfileReducer.Path1.Action.privacy, then: PrivacyView.init(store:))
            case .language:
                CaseLet(/ProfileReducer.Path1.State.language, action: ProfileReducer.Path1.Action.language, then: LanguageView.init(store:))
            }
        }
    }
    
    struct RootView: View {
        let store: StoreOf<ProfileReducer>
        var body: some View {
            WithViewStore(store, observe: {$0}) { viewStore in
                LazyVGrid(columns: [GridItem(.flexible())], content: {
                    ForEach(viewStore.items, id:\.self) { item in
                        Button(action: {viewStore.send(.itemDidSelected(item))}, label: {
                            HStack{
                                Image(item.icon)
                                Text(LocalizedStringKey(item.title)).font(.system(size: 16)).foregroundStyle(.black)
                                Spacer()
                                Image("profile_next")
                            }
                        }).padding(.all, 16)
                    }
                }).background(.white).cornerRadius(8).padding(.horizontal, 20).padding(.top, 40)
            }.background(Image("tracker_bg").resizable().ignoresSafeArea().scaledToFill())
        }
    }
}
