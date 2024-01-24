//
//  PrivacyView.swift
//  BPCureX
//
//  Created by yangjian on 2023/12/15.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct PrivacyReducer: Reducer {
    struct State: Equatable {}
    enum Action: Equatable {
        case pop
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            return .none
        }
    }
}

struct PrivacyView: View {
    let store: StoreOf<PrivacyReducer>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                List(){
                    VStack{
                        Text(LocalizedStringKey("privacy")).padding(.all, 16).foregroundColor(.black).font(.system(size: 15.0)).lineLimit(nil)
                        Spacer()
                    }
                }
            }.back(LocalizedStringKey(ProfileReducer.State.Item.privacy.title)) {
                viewStore.send(.pop)
            }
        }
    }
}
