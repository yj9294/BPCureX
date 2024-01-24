//
//  BPTrendsView.swift
//  BPCureX
//
//  Created by yangjian on 2023/12/14.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct BPTrendsReducer: Reducer {
    struct State: Equatable {
        @FileHelper(.measures, defaultValue: [])
        var measures: [Measurement]
        var filter: AnalyticsFilter.State = .init()
        var filterMeasures: [Measurement] {
            measures.filter { measure in
                measure.date > filter.duration.min && measure.date < filter.duration.max
            }
        }
        var dates: [Date] {
            filterMeasures.map { measure in
                measure.date
            }.reduce([]) { partialResult, d in
                if partialResult.isEmpty {
                    return [d]
                } else {
                    var array = partialResult
                    if partialResult.last?.exactlyDay != d.exactlyDay {
                        array.append(d)
                    }
                    return array
                }
            }
        }
        
        var systolic: [Int] {
            dates.map { date in
                filterMeasures.filter { measure in
                    return measure.date.exactlyDay == date.exactlyDay
                }.max { m1, m2 in
                    return m1.systolic < m2.systolic
                }?.systolic ?? 250
            }
        }
        var diastolic: [Int] {
            dates.map { date in
                filterMeasures.filter { measure in
                    return measure.date.exactlyDay == date.exactlyDay
                }.min { m1, m2 in
                    return m1.diastolic < m2.diastolic
                }?.diastolic ?? 30
            }
        }
        
        var averageSy: Int {
            if systolic.isEmpty {
                return 0
            }
            return systolic.reduce(0, +) / systolic.count
        }
        
        var averageDi: Int {
            if diastolic.isEmpty {
                return 0
            }
            return  diastolic.reduce(0, +) / diastolic.count
        }
        
        var numberUnit: [Int] {
            Array(1...8).map { index in
                index * 30
            }
        }
        
        var unitString: [String] {
            numberUnit.map {
                "\($0)"
            }.reversed()
        }
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

struct BPTrendsView: View {
    let store: StoreOf<BPTrendsReducer>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                AnalyticsFilterView(store: store.scope(state: \.filter, action: BPTrendsReducer.Action.filter))
                ScrollView{
                    VStack{
                        AnalyticsAverageView(item: .bp, value: "\(viewStore.averageSy)-\(viewStore.averageDi)")
                        ChartsView(store: store)
                        Spacer()
                    }
                }.background(.white)
            }.back(LocalizedStringKey(AnalyticsReducer.State.Item.bp.title)) {
                viewStore.send(.pop)
            }
        }
    }
    
    struct ChartsView: View {
        let store: StoreOf<BPTrendsReducer>
        var body: some View {
            WithViewStore(store, observe: {$0}) { viewStore in
                ZStack{
                    HStack(spacing: 15){
                        UnitView(source: viewStore.unitString)
                        DottedLineView(source: Array(1...8))
                    }.padding(.bottom, 20).padding(.top, 8)
                    DataView(store: store)
                }
            }.padding(.horizontal, 16)
        }
    }

    struct UnitView: View {
        let source: [String]
        var body: some View {
            VStack(spacing: 15){
                ForEach(source, id: \.self) { str in
                    Text(str).font(.system(size: 12)).foregroundStyle(Color("#A6BFC8")).frame(width: 30, height: 17)
                }
            }
        }
    }
 
    struct DottedLineView: View {
        let source: [Int]
        var body: some View {
            GeometryReader{ proxy in
                VStack(spacing: 15){
                    ForEach(source, id: \.self) { _ in
                        Path{ path in
                            path.move(to: CGPoint(x: 0, y: 7))
                            path.addLine(to: CGPoint(x: proxy.size.width, y: 7))
                        }.stroke(style: .init(lineWidth: 1.0)).foregroundColor(Color("#E5EAED"))
                    }
                }
            }
        }
    }

    struct DataView: View {
        let store: StoreOf<BPTrendsReducer>
        var body: some View {
            WithViewStore(store, observe: {$0}) { viewStore in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: [GridItem(.flexible())], spacing: 15) {
                        ForEach(viewStore.dates.indices, id: \.self) { index in
                            VStack(spacing: 0){
                                HStack{
                                    Spacer()
                                    GeometryReader{ proxy in
                                        VStack(spacing: 0){
                                            let systolic = Double(viewStore.systolic[index]) >= 240 ? 240.0 : Double(viewStore.systolic[index])
                                            let top = (240.0 - systolic) / 210.0 * (proxy.size.height - 17)
                                            let height = (Double(viewStore.systolic[index]) - Double(viewStore.diastolic[index])) / 210.0 * (proxy.size.height - 17)
                                            let status = Measurement.getStatus(systolic: viewStore.systolic[index], diastolic: viewStore.diastolic[index])
                                            Text(verbatim: "\(viewStore.systolic[index])").frame(height: 8.5).padding(.top, top)
                                            status.color.frame(width: 7.0, height: height).cornerRadius(3.5)
                                            Text(verbatim: "\(viewStore.diastolic[index])").frame(height: 8.5)
                                        }
                                    }.font(.system(size: 8.5))
                                    Spacer()
                                }
                                Text(viewStore.dates[index].unitDay).frame(height: 20)
                            }.font(.system(size: 10)).foregroundColor(Color("#A6BFC8"))
                        }
                    }
                }.padding(.leading, 45)
            }
        }
    }
}
