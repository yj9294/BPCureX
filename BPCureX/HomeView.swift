//
//  HomeView.swift
//  BPCureX
//
//  Created by yangjian on 2023/12/12.
//

import SwiftUI

import ComposableArchitecture

struct HomeReducer: Reducer {
    struct State: Equatable {
        let items: [Item] = Item.allCases
        var lastItem: Item = .tracker
        @BindingState var item: Item = .tracker
        var tracker: TrackerReducer.State = .init()
        var analytics: AnalyticsReducer.State = .init()
        var profile: ProfileReducer.State = .init()
        @PresentationState var add: AddReducer.State? = nil
        @PresentationState var disclaimer: DisclaimerReducer.State? = nil
        
        @FileHelper(.measures, defaultValue: [])
        var measures: [Measurement]
        
        @FileHelper(.guide, defaultValue: true)
        var isGuide: Bool
        
        @FileHelper(.disclaimer, defaultValue: true)
        var isDisclaimer: Bool
    }
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case tracker(TrackerReducer.Action)
        case analytics(AnalyticsReducer.Action)
        case profile(ProfileReducer.Action)
        
        case add(PresentationAction<AddReducer.Action>)
        case disclaimer(PresentationAction<DisclaimerReducer.Action>)
        
        case updateLastItem
        case resetLstItem
        case presentAddView
        case presentDisclaimerView
        
        case guideButtonTapped
    }
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce{ state, action in
            if case .updateLastItem = action {
                state.lastItem = state.item
            }
            if case .resetLstItem = action {
                state.item = state.lastItem
            }
            
            if case .presentAddView = action {
                state.presentAddView()
            }
            if case .add(.presented(.dismiss)) = action {
                state.dismissAddView()
            }
            
            if case .presentDisclaimerView = action {
                state.presentDisclaimerView()
            }
            if case .disclaimer(.presented(.okButtonTapped)) = action {
                state.dismissDisclaimerView()
            }
            
            if case .guideButtonTapped = action {
                state.isGuide = false
                state.presentAddView()
            }
            // edit view 点击 ok 按钮
            if case let .add(.presented(.path(.element(id: id, action: .edit(.update))))) = action {
                if case let .edit(editState) =  state.add?.path[id: id] {
                    state.addMeasure(editState.measure)
                    state.dismissAddView()
                }
            }
            
            // detail view 点击 edit 按钮
            if case let .tracker(.path(.element(id: id, action: .detail(.editButtonTapped)))) = action {
                if case let .detail(detailState) = state.tracker.path[id: id] {
                    state.presentAddView(detailState.measure, status: .edit)
                }
            }
            
            // detail view 点击 delete 按钮
            if case let .tracker(.path(.element(id: id, action: .detail(.deleteButtonTapped)))) = action {
                if case let .detail(detailState) = state.tracker.path[id: id] {
                    state.deleteMeasure(detailState.measure)
                }
            }


            return .none
        }.ifLet(\.$add, action: /Action.add) {
            AddReducer()
        }.ifLet(\.$disclaimer, action: /Action.disclaimer) {
            DisclaimerReducer()
        }
        
        Scope(state: \.tracker, action: /Action.tracker) {
            TrackerReducer()
        }
        Scope(state: \.analytics, action: /Action.analytics) {
            AnalyticsReducer()
        }
        Scope(state: \.profile, action: /Action.profile) {
            ProfileReducer()
        }
    }
}

extension HomeReducer.State {
    enum Item: String, CaseIterable {
        case tracker, add, analytics, profile
        var icon: String {
            return "home_\(self.rawValue)_unselected"
        }
        var selectedIcon: String {
            return "home_\(self.rawValue)_selected"
        }
    }
    
    mutating func presentAddView(_ measure: Measurement = .init(), status: AddReducer.State.Status = .new) {
        add = .init(status: status, measure: measure)
    }
    mutating func dismissAddView() {
        add = nil
    }
    
    mutating func presentDisclaimerView() {
        disclaimer = .init(item: .new)
    }
    
    mutating func dismissDisclaimerView() {
        isDisclaimer = false
        disclaimer = nil
    }
    
    mutating func addMeasure(_ measure: Measurement) {
        let contains = measures.contains {
            $0.id == measure.id
        }
        if contains {
           measures = measures.compactMap({
               if $0.id == measure.id {
                   return measure
               }
               return $0
           })
        } else {
            measures.insert(measure, at: 0)
        }
        updateMeasure()
    }
    
    mutating func deleteMeasure(_ measure: Measurement) {
        measures = measures.filter({
            $0.id != measure.id
        })
        updateMeasure()
    }
    
    mutating func updateMeasure() {
        tracker.measures = measures
        analytics.measures = measures
    }
}

struct HomeView: View {
    let store: StoreOf<HomeReducer>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            ZStack{
                TabView(selection: viewStore.$item) {
                    ForEach(viewStore.items, id:\.self) { item in
                        getTabItem(item, in: store)
                    }
                }
                if viewStore.isGuide {
                    GuideView {
                        viewStore.send(.guideButtonTapped)
                    }
                }
            }.onAppear{
                if viewStore.isDisclaimer {
                    viewStore.send(.presentDisclaimerView)
                }
            }
            .fullScreenCover(store: store.scope(state: \.$disclaimer, action: {.disclaimer($0)})) { store in
                DisclaimerView(store: store)
            }
            .fullScreenCover(store: store.scope(state: \.$add, action: {.add($0)})) { store in
                AddView(store: store)
            }
        }
    }
    
    func getTabItem(_ item: HomeReducer.State.Item, in viewStore: StoreOf<HomeReducer>) -> some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                switch viewStore.state.item {
                case .tracker:
                    TrackerView(store: store.scope(state: \.tracker, action: {.tracker($0)}))
                case .add:
                    EmptyView()
                case .analytics:
                    AnalyticsView(store: store.scope(state: \.analytics, action: {.analytics($0)}))
                case .profile:
                    ProfileView(store: store.scope(state: \.profile, action: {.profile($0)}))
                }
            }.tabItem {
                Image(viewStore.item == item ? item.selectedIcon : item.icon)
            }.onChange(of: viewStore.item) { newValue in
                if newValue == .add {
                    viewStore.send(.resetLstItem)
                    viewStore.send(.presentAddView)
                } else {
                    viewStore.send(.updateLastItem)
                }
            }
            
        }
    }
    
    struct GuideView: View {
        let action: ()->Void
        var body: some View {
            VStack(spacing: 30){
                Spacer()
                Image("guide_icon")
                Text(LocalizedStringKey("Record blood pressure status"))
                Button(action: action, label: {
                    HStack{
                        Image("guide_add")
                        Text(LocalizedStringKey("Add"))
                    }.padding(.vertical, 15).padding(.horizontal, 75).background(Color("#3654E6").cornerRadius(30))
                })
                HStack{Spacer()}
                Spacer()
            }.foregroundColor(.white).font(.system(size: 16.0)).background(.black.opacity(0.45))
        }
    }
}
