//
//  DisclaimerView.swift
//  BPCureX
//
//  Created by yangjian on 2024/1/31.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct DisclaimerReducer: Reducer {
    struct State: Equatable {
        // 进入时首次打开还是冲设置进入
        var item: DisclaimerItem = .scan
        enum DisclaimerItem {
            case new, scan
        }
        
        var isNew: Bool {
            item == .new
        }
    }
    enum Action: Equatable {
        case pop
        case okButtonTapped
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            return .none
        }
    }
}

struct DisclaimerView: View {
    let store: StoreOf<DisclaimerReducer>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            if viewStore.isNew {
                VStack{
                    List(){
                        VStack{
                            Text(LocalizedStringKey("disclaimer1"))
                            +
                            Text(LocalizedStringKey("disclaimer2"))
                            Spacer()
                        }.foregroundColor(.black).font(.system(size: 15.0)).lineLimit(nil)
                    }
                    VStack{
                        Button(action: {
                            viewStore.send(.okButtonTapped)
                        }, label: {
                            HStack{
                                Spacer()
                                Text("OK").padding(.vertical, 13).foregroundColor(.white)
                                Spacer()
                            }
                        }).background(.linearGradient(colors: [Color("#5874FF"), Color("#3654E6")], startPoint: .topLeading, endPoint: .bottomTrailing)).cornerRadius(24)
                    }.padding(.vertical, 25).padding(.horizontal, 70)
                }
            } else {
                List(){
                    VStack{
                        Text(LocalizedStringKey("disclaimer1"))
                        +
                        Text(LocalizedStringKey("disclaimer2"))
                        Spacer()
                    }.foregroundColor(.black).font(.system(size: 15.0)).lineLimit(nil)
                }.back(LocalizedStringKey(ProfileReducer.State.Item.disclaimer.title)) {
                    viewStore.send(.pop)
                }
            }
            
        }
    }
}
