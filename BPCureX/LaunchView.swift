//
//  LaunchView.swift
//  BPCureX
//
//  Created by yangjian on 2023/12/12.
//

import SwiftUI

import ComposableArchitecture

struct LaunchReducer: Reducer {
    enum CancelID { case timer }
    struct State: Equatable {
        var progress = 0.0
        var duration = 2.5
        
        var isLaunched: Bool {
            progress == 1.0
        }
    }
    enum Action: Equatable {
        case start
        case update
        case stop
    }
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        if case .start = action {
            state.progress = 0.0
            state.duration = 2.5
            let publisher = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect().map { _ in
                Action.update
            }
            return .publisher {
                publisher
            }.cancellable(id: CancelID.timer)
        }
        if case .update = action {
            state.progress += 0.02 / state.duration
            state.progress = state.progress >= 1.0 ? 1.0 : state.progress
        }
        if case .stop = action {
            return .cancel(id: CancelID.timer)
        }
        return .none
    }
}

struct LaunchView: View {
    let store: StoreOf<LaunchReducer>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                Image("launch_icon").padding(.top, 109)
                Spacer()
                VStack(spacing:86){
                    Image("launch_title")
                    ProgressView("", value: viewStore.progress).tint(Color("#5874FF")).padding(.horizontal, 80)
                }.padding(.bottom, 43)
            }.background(Image("launch_bg").resizable().ignoresSafeArea()).onDisappear {
                viewStore.send(.stop)
            }.onAppear {
                viewStore.send(.start)
            }
        }
    }
}

