//
//  DetailView.swift
//  BPCureX
//
//  Created by yangjian on 2023/12/13.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct DetailReducer: Reducer {
    struct State: Equatable {
        let measure: Measurement
    }
    enum Action: Equatable {
        case pop
        case editButtonTapped
        case deleteButtonTapped
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            return .none
        }
    }
}

struct DetailView: View {
    let store: StoreOf<DetailReducer>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                MeasureView(measure: viewStore.measure)
                ButtonView {
                    viewStore.send(.deleteButtonTapped)
                }
                Spacer()
            }.background(Color("#F3F8FB")).back(LocalizedStringKey("Details")) {
                viewStore.send(.pop)
            }.right({
                viewStore.send(.editButtonTapped)
            }, label: {
                Image("detail_edit")
            })
        }
    }
    
    struct MeasureView: View {
        let measure: Measurement
        var body: some View {
            VStack{
                VStack(spacing: 10){
                    HStack{
                        Text(measure.date.detail)
                        Spacer()
                        Text(LocalizedStringKey(measure.status.title))
                    }.padding(.horizontal, 6).padding(.vertical,3).background(measure.status.color).cornerRadius(5).font(.system(size: 12)).foregroundColor(.white)
                    HStack{
                        TrackerView.TrackerCell.MeasureCell(item: .sys, value: measure.systolic)
                        Spacer()
                        TrackerView.TrackerCell.MeasureCell(item: .dia, value: measure.diastolic)
                        Spacer()
                        TrackerView.TrackerCell.MeasureCell(item: .pulse, value: measure.pulse)
                    }
                    Divider()
                    HStack{
                        Text(measure.note).foregroundStyle(Color("#BBCDD9")).lineLimit(nil).font(.system(size: 12)).truncationMode(.tail)
                        Spacer()
                    }
                }.padding(.horizontal, 20).padding(.vertical,12).background(.white).cornerRadius(8)
            }.padding(.horizontal, 20).padding(.vertical, 16)
        }
    }
    
    struct ButtonView: View {
        let action: ()->Void
        var body: some View {
            Button(action: action) {
                Text(LocalizedStringKey("Delete")).foregroundStyle(.white)
            }.background(Image("detail_button_bg"))
        }
    }
}
