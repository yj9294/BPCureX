//
//  TrackerView.swift
//  BPCureX
//
//  Created by yangjian on 2023/12/12.
//

import Foundation
import SwiftUI
import AppTrackingTransparency
import ComposableArchitecture

struct TrackerReducer: Reducer {
    struct State: Equatable {
        @FileHelper(FileKey.measures, defaultValue: [])
        var measures: [Measurement]
        @FileHelper(FileKey.duration, defaultValue: .default)
        var duration: DateDuration
        var path: StackState<Path.State> = .init()
        @PresentationState var datePicker:DatePickerReducer.State? = nil
    }
    enum Action: Equatable {
        case path(StackAction<Path.State, Path.Action>)
        case lastDuration
        case nextDuration
        case itemDidSelected(Measurement)
        case minDateButtonTapped
        case maxDateButtonTapped
        case datePicker(PresentationAction<DatePickerReducer.Action>)
    }
    
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            if case .lastDuration = action {
                state.lastFilterDate()
            }
            if case .nextDuration = action {
                state.nextFilterDate()
            }
            if case let .itemDidSelected(measure) = action {
                state.pushDetailView(measure)
            }
            if case .path(.element(id:_, action: .detail(.pop))) = action {
                state.popDetailView()
            }
            if case .path(.element(id:_, action: .detail(.editButtonTapped))) = action {
                state.popDetailView()
            }
            if case .path(.element(id:_, action: .detail(.deleteButtonTapped))) = action {
                state.popDetailView()
            }
            
            if case .minDateButtonTapped = action {
                state.datePicker = .init(date: state.duration.min, postion: .filterMin, components: [.date, .hourAndMinute])
            }
            if case .maxDateButtonTapped = action {
                state.datePicker = .init(date: state.duration.max, postion: .filterMax, components: [.date, .hourAndMinute])
            }
            if case .datePicker(.presented(.cancel)) = action {
                state.datePicker = nil
            }
            if case let .datePicker(.presented(.ok(date, position))) = action {
                if position == .filterMin {
                    state.duration.min = date
                    if date > state.duration.max {
                        state.duration.max = date.addingTimeInterval(.day)
                    }
                }
                if position == .filterMax {
                    state.duration.max = date
                    if date < state.duration.min {
                        state.duration.min = date.addingTimeInterval(-.day)
                    }
                }
                state.datePicker = nil
            }
            return .none
        }.forEach(\.path, action: /Action.path) {
            Path()
        }.ifLet(\.$datePicker, action: /Action.datePicker) {
            DatePickerReducer()
        }
    }
    
    struct Path: Reducer {
        enum State: Equatable {
            case detail(DetailReducer.State)
        }
        enum Action: Equatable {
            case detail(DetailReducer.Action)
        }
        var body: some Reducer<State, Action> {
            Reduce{ state, action in
                return .none
            }
            Scope(state: /State.detail, action: /Action.detail) {
                DetailReducer()
            }
        }
    }
}

extension TrackerReducer.State {
    var measure: Measurement? {
        measures.first
    }
    
    var filterMeasures: [Measurement] {
        let array = measures.filter { measure in
            measure.date > duration.min.exactlyDay && measure.date < duration.max.exactlyDay
        }
        return array
    }
    
    mutating func lastFilterDate() {
        duration.max = duration.max.addingTimeInterval(-.weak)
        duration.min = duration.min.addingTimeInterval(-.weak)
    }
    mutating func nextFilterDate() {
        duration.max = duration.max.addingTimeInterval(.weak)
        duration.min = duration.min.addingTimeInterval(.weak)
    }
    mutating func pushDetailView(_ measure: Measurement) {
        path.append(.detail(.init(measure: measure)))
    }
    
    mutating func popDetailView() {
        path.removeAll()
    }
}

struct TrackerView: View {
    let store: StoreOf<TrackerReducer>
    var body: some View {
        NavigationStackStore(store.scope(state: \.path, action: {.path($0)})) {
            RootView(store: store)
                .fullScreenCover(store: store.scope(state: \.$datePicker, action: TrackerReducer.Action.datePicker)) { store in
                    DatePickerView(store: store)
                }
        } destination: {
            switch $0 {
            case .detail:
                CaseLet(/TrackerReducer.Path.State.detail, action: TrackerReducer.Path.Action.detail, then: DetailView.init(store:))
            }
        }
    }
    
    struct RootView: View {
        let store: StoreOf<TrackerReducer>
        var body: some View {
            WithViewStore(store, observe: {$0}) { viewStore in
                ScrollView{
                    VStack(spacing: 14){
                        HStack{Spacer()}
                        if let measure = viewStore.measure {
                            Button {
                                viewStore.send(.itemDidSelected(measure))
                            } label: {
                                TrackerCell(measure: measure).padding(.horizontal, 20)
                            }
                        }
                        DateCell(duration: viewStore.duration) {
                            viewStore.send(.lastDuration)
                        } nextAction: {
                            viewStore.send(.nextDuration)
                        } minButtonAction: {
                            viewStore.send(.minDateButtonTapped)
                        } maxButtonAction: {
                            viewStore.send(.maxDateButtonTapped)
                        }
                        MeasuresView(measures: viewStore.filterMeasures) { item in
                            viewStore.send(.itemDidSelected(item))
                        }
                        Spacer()
                    }
                }.background(Image("tracker_bg").resizable().ignoresSafeArea()).navigationTitle(LocalizedStringKey("Tracker")).navigationBarTitleDisplayMode(.inline)
            }.onAppear{
                Task{
                    await ATTrackingManager.requestTrackingAuthorization()
                }
            }
        }
    }
    
    struct TrackerCell: View {
        let measure: Measurement
        var body: some View {
            VStack{
                HStack(spacing: 4){
                    Image(measure.posture.feel.icon).resizable().frame(width: 24, height: 24)
                    Image(measure.posture.arm.icon).resizable().frame(width: 24, height: 24)
                    Image(measure.posture.body.icon).resizable().frame(width: 24, height: 24)
                    Spacer()
                    HStack{
                        Spacer()
                        Text(measure.date.detail)
                        Text(LocalizedStringKey(measure.status.title))
                    }.padding(.horizontal, 6).padding(.vertical,3).font(.system(size: 12)).lineLimit(1).foregroundColor(.white).background(measure.status.color).cornerRadius(5)
                }
                HStack{
                    MeasureCell(item: .sys, value: measure.systolic)
                    Spacer()
                    MeasureCell(item: .dia, value: measure.diastolic)
                    Spacer()
                    MeasureCell(item: .pulse, value: measure.pulse)
                }
            }.padding(.top, 10).padding(.horizontal, 20).padding(.bottom, 14).background(.white).cornerRadius(8)
        }
        
        struct MeasureCell: View {
            let item: AddReducer.State.Item
            let value: Int
            var body: some View {
                VStack{
                    Text("\(value)").font(.system(size: 32, weight: .medium))
                    Text(item.unit).font(.system(size: 11.0))
                }.padding(.vertical, 10).padding(.horizontal, 12).foregroundColor(.black).background(.linearGradient(colors: [Color("#96ADF6"), Color("#C6DCF5")], startPoint: .top, endPoint: .bottom).opacity(0.2)).cornerRadius(8)
            }
        }
    }
    
    struct DateCell: View {
        let duration: DateDuration
        let lastAction: ()->Void
        let nextAction: ()->Void
        let minButtonAction: ()->Void
        let maxButtonAction: ()->Void
        var body: some View {
            HStack{
                HStack{
                    Button(action: lastAction) {
                        Image("tracker_last")
                    }
                    HStack{
                        Button(action: minButtonAction, label: {
                            Text(duration.min.exactlyDay.day)
                        })
                        Text(" ~ ")
                        Button(action: maxButtonAction, label: {
                            Text(duration.max.exactlyDay.day)
                        })
                    }.font(.system(size: 12))
                    Button(action: nextAction) {
                        Image("tracker_next")
                    }
                }.padding(.horizontal, 16).padding(.vertical, 10).background(.linearGradient(colors: [Color("#FFBD37"), Color("#FF8C05")], startPoint: .leading, endPoint: .trailing).opacity(0.2)).cornerRadius(16)
            }.padding(.horizontal, 70)
        }
    }
    
    struct MeasuresView: View {
        let measures: [Measurement]
        let action: (Measurement)->Void
        var body: some View {
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 12){
                ForEach(measures) { measure in
                    Button {
                        action(measure)
                    } label: {
                        TrackerCell(measure: measure)
                    }
                }
            }.padding(.horizontal, 20).padding(.vertical, 10)
        }
    }
}

