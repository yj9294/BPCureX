//
//  BPProportionView.swift
//  BPCureX
//
//  Created by yangjian on 2023/12/14.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct BPProportionReducer: Reducer {
    struct State: Equatable {
        @FileHelper(.measures, defaultValue: [])
        var measures: [Measurement]
        var filter: AnalyticsFilter.State = .init()
        var filterMeasures: [Measurement] {
            measures.filter { measure in
                measure.date > filter.duration.min && measure.date < filter.duration.max
            }
        }
        var progress: Double {
            if filterMeasures.isEmpty {
                return 0.0
            }
            let filter = filterMeasures
            let array = filterMeasures.filter({$0.status == .normal})
            return Double(array.count) / Double(filter.count)
        }
        var progresses: [Double] {
            if filterMeasures.count == 0 {
                return []
            }
            let filter = filterMeasures
            return Measurement.Status.allCases.map { status in
                let array = filterMeasures.filter({$0.status == status})
                return Double(array.count) / Double(filter.count)
            }
        }
        let colors = Measurement.Status.uiColors
    }
    enum Action: Equatable {
        case pop
        case filter(AnalyticsFilter.Action)
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            return .none
        }
        Scope(state: \.filter, action: /Action.filter) {
            AnalyticsFilter()
        }
    }
}

struct BPProportionView: View {
    let store: StoreOf<BPProportionReducer>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                AnalyticsFilterView(store: store.scope(state: \.filter, action: BPProportionReducer.Action.filter))
                ScrollView{
                    VStack{
                        CenterCircleView(store: store)
                        ColorsView()
                        Spacer()
                    }
                }.background(.white)
            }.back(LocalizedStringKey(AnalyticsReducer.State.Item.proportion.title)) {
                viewStore.send(.pop)
            }
        }
    }
    
    struct CenterCircleView: View {
        let store: StoreOf<BPProportionReducer>
        var body: some View {
            WithViewStore(store, observe: {$0}) { viewStore in
                VStack{
                    ZStack{
                        CircleView(progress: viewStore.progresses, colors: viewStore.colors, lineWidth: 50).frame(width: 250, height: 250)
                        Text("\(Int(viewStore.progress * 100))%").font(.system(size: 33))
                            .foregroundStyle(.black)
                    }
                    
                    Text(LocalizedStringKey("\(Int(viewStore.progress) * 100)% is the proportion of normal blood pressure values")).foregroundStyle(.black).font(.system(size: 16)).padding(.horizontal, 70).truncationMode(.tail).lineLimit(nil).multilineTextAlignment(.center)
                }
            }
        }
    }
    
    struct ColorsView: View {
        var body: some View {
            VStack{
                LazyVGrid(columns: [GridItem(.flexible())], spacing: 12) {
                    ForEach(Measurement.Status.allCases, id: \.self) { item in
                        HStack{
                            Text(LocalizedStringKey(item.title))
                            Spacer()
                        }.padding(.horizontal, 8).padding(.vertical, 2).background(item.color).cornerRadius(10).font(.system(size: 12.0)).foregroundColor(.white)
                    }
                }.padding(.horizontal, 50)
            }
        }
    }
}
