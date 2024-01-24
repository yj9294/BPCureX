//
//  AnalyticsView.swift
//  BPCureX
//
//  Created by yangjian on 2023/12/12.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct AnalyticsReducer: Reducer {
    struct State: Equatable {
        @FileHelper(.measures, defaultValue: [])
        var measures: [Measurement]
        var path: StackState<Path.State> = .init()
        let items: [Item] = Item.allCases
    }
    enum Action: Equatable {
        case path(StackAction<Path.State, Path.Action>)
        case itemDidSelected(State.Item)
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            if case let .itemDidSelected(item) = action {
                state.pushView(item)
            }
            if case .path(.element(id:_, action: .proportion(.pop))) = action {
                state.popView()
            }
            if case .path(.element(id:_, action: .bp(.pop))) = action {
                state.popView()
            }
            if case .path(.element(id:_, action: .map(.pop))) = action {
                state.popView()
            }
            if case .path(.element(id:_, action: .heart(.pop))) = action {
                state.popView()
            }
            return .none
        }.forEach(\.path, action: /Action.path) {
            Path()
        }
    }
    
    struct Path: Reducer {
        enum State: Equatable {
            case proportion(BPProportionReducer.State)
            case bp(BPTrendsReducer.State)
            case map(MAPTrendsReducer.State)
            case heart(HeartRateReducer.State)
        }
        enum Action: Equatable {
            case proportion(BPProportionReducer.Action)
            case bp(BPTrendsReducer.Action)
            case map(MAPTrendsReducer.Action)
            case heart(HeartRateReducer.Action)
        }
        var body: some Reducer<State, Action> {
            Reduce{ state, action in
                return .none
            }
            Scope(state: /State.proportion, action: /Action.proportion) {
                BPProportionReducer()
            }
            Scope(state: /State.bp, action: /Action.bp) {
                BPTrendsReducer()
            }
            Scope(state: /State.map, action: /Action.map) {
                MAPTrendsReducer()
            }
            Scope(state: /State.heart, action: /Action.heart) {
                HeartRateReducer()
            }
        }
    }
}

extension AnalyticsReducer.State {
    enum Item: CaseIterable{
        case proportion, bp, map, heart
        var title: String {
            switch self {
            case .proportion:
                return "BP Proportion"
            case .bp:
                return "BP Trends"
            case .map:
                return "MAP Trends"
            case .heart:
                return "Heart Rate"
            }
        }
        var unit: String {
            switch self {
            case .bp, .map:
                return "mmHg"
            default:
                return "BPM"
            }
        }
        var normalRange: String {
            switch self {
            case .bp:
                return "120-80"
            case .map:
                return "79-110"
            default:
                return ""
            }
        }
        var words: String {
            switch self {
            case .bp, .map:
                return "BP"
            default:
                return "HR"
            }
        }
        var headline: String {
            return "The proportion of normal blood pressure values"
        }
    }
    mutating func pushView(_ item: Item) {
        switch item {
        case .proportion:
            path.append(.proportion(.init()))
        case .bp:
            path.append(.bp(.init()))
        case .map:
            path.append(.map(.init()))
        case .heart:
            path.append(.heart(.init()))
        }
    }
    mutating func popView() {
        path.removeAll()
    }
}

struct AnalyticsView: View {
    let store: StoreOf<AnalyticsReducer>
    var body: some View {
        NavigationStackStore(store.scope(state: \.path, action: {.path($0)})) {
            RootView(store: store)
        } destination: {
            switch $0 {
            case .proportion:
                CaseLet(/AnalyticsReducer.Path.State.proportion, action: AnalyticsReducer.Path.Action.proportion, then: BPProportionView.init(store:))
            case .bp:
                CaseLet(/AnalyticsReducer.Path.State.bp, action: AnalyticsReducer.Path.Action.bp, then: BPTrendsView.init(store:))
            case .map(_):
                CaseLet(/AnalyticsReducer.Path.State.map, action: AnalyticsReducer.Path.Action.map, then: MAPTrendsView.init(store:))
            case .heart(_):
                CaseLet(/AnalyticsReducer.Path.State.heart, action: AnalyticsReducer.Path.Action.heart, then: HeartRateView.init(store:))
            }
        }
    }
    
    struct RootView: View {
        let store: StoreOf<AnalyticsReducer>
        var body: some View {
            WithViewStore(store, observe: {$0}) { viewStore in
                VStack{
                    Spacer()
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 0), GridItem(.flexible(), spacing: 0)], spacing: 0) {
                        ForEach(viewStore.items.indices, id: \.self) { index in
                            Button {
                                viewStore.send(.itemDidSelected(viewStore.items[index]))
                            } label: {
                                VStack(spacing: 0){
                                    VStack(spacing: 0){
                                        if index == 0 {
                                            ProportionCell(measures: viewStore.measures)
                                        } else {
                                            AnalyticsCell(text: viewStore.items[index].title, index: index)
                                        }
                                    }
                                    if index < 2 {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }.padding(.all, 15).background(.white).cornerRadius(8).padding(.horizontal, 20)
                    Spacer()
                }.background(Image("tracker_bg")).navigationTitle(LocalizedStringKey("Analytics Data")).navigationBarTitleDisplayMode(.inline)
            }
        }
        
        struct AnalyticsCell: View {
            let text: String
            let index: Int
            var body: some View {
                HStack(spacing: 0){
                    VStack(spacing: 32){
                        Image("analytics_icon").padding(.top, 20).padding([.leading,.bottom,.trailing], 10)
                        HStack{
                            Spacer()
                            Text(LocalizedStringKey(text)).padding(.vertical, 7).padding(.horizontal,5).font(.system(size: 14)).foregroundStyle(.white)
                            Spacer()
                        }.background(.linearGradient(colors: [Color("#FFBD37"), Color("#FF8C05")], startPoint: .leading, endPoint: .trailing)).cornerRadius(16)
                            .padding(.horizontal, 14).padding(.bottom, 20)
                    }
                    if index % 2 == 0 {
                        Divider()
                    }
                }
            }
        }
        
        struct ProportionCell: View {
            let measures: [Measurement]
            var progress: Double {
                if measures.isEmpty {
                    return 0.0
                }
                let normal = measures.filter {
                    $0.status == .normal
                }
                return Double(normal.count) / Double(measures.count)
            }
            var body: some View {
                HStack(spacing: 0){
                    VStack(spacing: 27){
                        ZStack{
                            Image("analytics_proportion")
                            Text("\(Int((progress * 100)))%")
                        }.padding(.horizontal, 20)
                        HStack{
                            Spacer()
                            Text(LocalizedStringKey(AnalyticsReducer.State.Item.proportion.headline))
                            Spacer()
                        }
                    }.foregroundStyle(.black).font(.system(size: 12.0))
                    Divider()
                }
            }
        }
        
    }
}

struct AnalyticsFilter: Reducer {
    struct State: Equatable {
        let items: [Item] = Item.allCases
        var item: Item = .twoweeks
        var duration: DateDuration {
            let min: Date = Date().exactlyDay.addingTimeInterval(-(.weak * Double(item.unit)) + 1)
            let max: Date = Date().exactlyDay.addingTimeInterval(.day)
            return DateDuration(min: min, max: max)
        }
        enum Item: CaseIterable {
            case week, twoweeks, month
            var unit: Int {
                switch self {
                case .week:
                    return 7
                case .twoweeks:
                    return 14
                case .month:
                    return 30
                }
            }
            var title: String {
                "\(unit) Days"
            }
        }
    }
    enum Action: Equatable {
        case didSelectedItem(State.Item)
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            if case let .didSelectedItem(item) = action {
                state.item = item
            }
            return .none
        }
    }
}

struct AnalyticsFilterView: View {
    let store: StoreOf<AnalyticsFilter>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            LazyHGrid(rows: [GridItem(.flexible())], spacing: 20) {
                ForEach(viewStore.items, id:\.self) { item in
                    Button {
                        viewStore.send(.didSelectedItem(item))
                    } label: {
                        VStack(spacing: 0){
                            if item != viewStore.item {
                                Text(item.title).foregroundStyle(Color("#8388A1")).padding(.vertical, 12).padding(.horizontal, 14).background(Color("#DDE2FE")).cornerRadius(8)
                            } else {
                                ZStack(alignment: .bottom){
                                    Text(item.title).foregroundStyle(.white).padding(.vertical, 12).padding(.horizontal, 14).background(Color("#5874FF")).cornerRadius(8)
                                    Image("proportion_point").padding(.bottom, -5)
                                }
                            }
                        }
                    }
                }
            }.frame(height:50).font(.system(size: 18)).padding(.horizontal, 32).padding(.vertical, 20)
        }
    }
}

struct AnalyticsAverageView: View {
    let item: AnalyticsReducer.State.Item
    let value: String
    var body: some View {
        VStack(spacing: 14.0){
            HStack{Spacer()}
            VStack(spacing: 6){
                VStack(spacing: 13){
                    Text(LocalizedStringKey("Your Average \(item.words)")).foregroundStyle(Color("#BBCDD9")).font(.system(size: 13))
                    Text(value).font(.system(size: 42)).foregroundStyle(.white)
                }
                HStack{
                    Spacer()
                    Text(item.unit).foregroundStyle(Color("#BBCDD9")).font(.system(size: 16))
                    Spacer()
                }
            }.padding(.vertical, 12).background(Image("analytics_bg")).cornerRadius(12).padding(.horizontal, 60)
            if item != .heart {
                Text(LocalizedStringKey("The normal range \(item.normalRange) mmHg")).foregroundStyle(Color("#C4CCD0")).font(.system(size: 12.0))
            }
        }
    }
}
