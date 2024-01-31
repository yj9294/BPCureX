//
//  MAPTrendsView.swift
//  BPCureX
//
//  Created by yangjian on 2023/12/14.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct MAPTrendsReducer: Reducer {
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
        var average: [Int] {
            dates.map { date in
                let totalDayAverage = filterMeasures.filter { measure in
                    return measure.date.exactlyDay == date.exactlyDay
                }.map { measure in
                    Double(measure.systolic + 2 * measure.diastolic) / 3.0
                }.reduce(0, +)
                let count = filterMeasures.filter { measure in
                    return measure.date.exactlyDay == date.exactlyDay
                }.count
                return Int(totalDayAverage / Double(count))
            }
        }
        
        var averageValue: Int {
            if dates.isEmpty {
                return 0
            }
            return Int(Double(average.reduce(0, +)) / Double(dates.count))
        }
        
        var numberUnit: [Int] {
            Array(0...5).map { index in
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

struct MAPTrendsView: View {
    let store: StoreOf<MAPTrendsReducer>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                AnalyticsFilterView(store: store.scope(state: \.filter, action: MAPTrendsReducer.Action.filter))
                ScrollView{
                    VStack{
                        AnalyticsAverageView(item: .map, value: "\(viewStore.averageValue)")
                        ChartsView(store: store)
                        Spacer()
                    }
                }.background(.white)
            }.back(LocalizedStringKey(AnalyticsReducer.State.Item.map.title)) {
                viewStore.send(.pop)
            }
        }
    }
    
    struct ChartsView: View {
        let store: StoreOf<MAPTrendsReducer>
        var body: some View {
            WithViewStore(store, observe: {$0}) { viewStore in
                ZStack{
                    HStack(spacing: 15){
                        UnitView(source: viewStore.unitString)
                        DottedLineView(source: Array(0...5))
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
        let store: StoreOf<MAPTrendsReducer>
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
                                            let da = Double(viewStore.average[index])
                                            let average = Double(da) >= 150.0 ? 150.0 : da
                                            let top = (150.0 - average) / 150.0 * (proxy.size.height - 16.0)
                                            let height = Double(da) / 150.0 * (proxy.size.height - 16.0)
                                            Text(verbatim: "\(Int(da))").frame(height: 16).padding(.top, top)
                                            HStack{
                                                Spacer()
                                                if index % 2 == 0 {
                                                    Color("#3654E6").frame(width: 7.0, height: height).cornerRadius(3.5)
                                                } else {
                                                    Color("#DDE3FF").frame(width: 7.0, height: height).cornerRadius(3.5)
                                                }
                                                Spacer()
                                            }
                                        }
                                    }.padding(.bottom, 8)
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
