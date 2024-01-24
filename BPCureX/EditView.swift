//
//  EditView.swift
//  BPCureX
//
//  Created by yangjian on 2023/12/12.
//

import Foundation
import SwiftUI
import Combine
import ComposableArchitecture

struct EditReducer: Reducer {
    struct State: Equatable {
        var status: AddReducer.State.Status = .new
        @BindingState var measure: Measurement
        @PresentationState var datePicker: DatePickerReducer.State? = nil
    }
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case pop
        case update
        case datePicker(PresentationAction<DatePickerReducer.Action>)
        case dateButtonTapped
    }
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce{ state, action in
            if case .dateButtonTapped = action {
                if state.status == .edit {
                    return .none
                }
                state.datePicker = .init(date: state.measure.date, postion: .newMeasure, components: [.date, .hourAndMinute])
            }
            if case .datePicker(.presented(.cancel)) = action {
                state.datePicker = nil
            }
            if case let .datePicker(.presented(.ok(date, position))) = action {
                if position == .newMeasure {
                    state.measure.date = date
                }
                state.datePicker = nil
            }
            return .none
        }.ifLet(\.$datePicker, action: /Action.datePicker) {
            DatePickerReducer()
        }
    }
}

struct EditView: View {
    let store: StoreOf<EditReducer>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            ScrollView{
                VStack{
                    MeasureView(measure: viewStore.measure)
                    ContentView(measure: viewStore.$measure) {
                        viewStore.send(.dateButtonTapped)
                    }
                    ButtonView {
                        viewStore.send(.update)
                    }
                    Spacer()
                }
            }.back(LocalizedStringKey(viewStore.status.title)) {
                viewStore.send(.pop)
            }.fullScreenCover(store: store.scope(state: \.$datePicker, action: EditReducer.Action.datePicker)) { store in
                DatePickerView(store: store)
            }
        }
    }
    
    struct MeasureView: View {
        let measure: Measurement
        var body: some View {
            VStack{
                HStack{
                    Spacer()
                    Text(measure.status.title).font(.system(size: 12)).foregroundStyle(.white)
                    Spacer()
                }.background(measure.status.color).cornerRadius(5)
                HStack{
                    MeasureCell(item: .sys, value: measure.systolic)
                    Spacer()
                    MeasureCell(item: .dia, value: measure.diastolic)
                    Spacer()
                    MeasureCell(item: .pulse, value: measure.pulse)
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
            .background(.white).cornerRadius(8)
            .padding(.vertical, 16).padding(.horizontal, 20)
        }
        
        struct MeasureCell: View {
            let item: AddReducer.State.Item
            let value: Int
            var body: some View {
                VStack{
                    Text("\(value)").font(.system(size: 32, weight: .medium))
                    Text(item.unit).font(.system(size: 11.0))
                }.padding(.vertical, 10).padding(.horizontal, 12).foregroundColor(.white).background(.linearGradient(colors: [Color("#FFBD37"), Color("#FF8C05")], startPoint: .top, endPoint: .bottom)).cornerRadius(8)
            }
        }
    }
    
    struct ContentView: View {
        @Binding var measure: Measurement
        let action: ()->Void
        var body: some View {
            VStack{
                ContentDateCell(action: {
                    action()
                }, value: measure.date.dateAndTime)
                ContentFeelCell(action: { item in
                    measure.posture.feel = item
                }, posture: measure.posture)
                ContentArmCell(action: { item in
                    measure.posture.arm = item
                }, posture: measure.posture)
                ContentBodyCell(action: { item in
                    measure.posture.body = item
                }, posture: measure.posture)
                ContentNoteCell(measure: $measure)
            }.padding(.all, 16).background(Image("edit_bg").resizable()).padding(.horizontal, 20)
        }
        
        struct ContentDateCell: View {
            let action: ()->Void
            let value: String
            var body: some View {
                Button(action: action) {
                    HStack(spacing: 8){
                        Image("edit_calendar")
                        Text(value)
                        Spacer()
                        Image("edit_edit")
                    }.font(.system(size: 14.0)).foregroundStyle(Color("#8F8FA3"))
                }
                .padding(.vertical, 15).padding(.horizontal, 12).background(.white).cornerRadius(8)
            }
        }
        
        struct ContentFeelCell: View {
            let action: (Measurement.Posture.Feel)->Void
            let posture: Measurement.Posture
            var body: some View {
                HStack{
                    Text(LocalizedStringKey("Feeling")).foregroundStyle(Color("#415FEE")).font(.system(size: 16))
                    Spacer()
                    ForEach(Measurement.Posture.Feel.allCases, id: \.self) { item in
                        Button(action: {
                            action(item)
                        }) {
                            VStack{
                                Image(item.icon)
                                Image("edit_selected").opacity(posture.feel == item ? 1.0 : 0.0)
                            }
                        }
                    }
                }.padding(.horizontal, 12).padding(.vertical, 10).background(.white).cornerRadius(8)
            }
        }
        
        struct ContentArmCell: View {
            let action: (Measurement.Posture.Arm)->Void
            let posture: Measurement.Posture
            var body: some View {
                HStack{
                    Text(LocalizedStringKey("Measured arm")).foregroundStyle(Color("#415FEE")).font(.system(size: 16))
                    Spacer()
                    ForEach(Measurement.Posture.Arm.allCases, id: \.self) { item in
                        Button(action: {
                            action(item)
                        }) {
                            VStack{
                                Image(item.icon)
                                Image("edit_selected").opacity(posture.arm == item ? 1.0 : 0.0)
                            }
                        }
                    }
                }.padding(.horizontal, 12).padding(.vertical, 10).background(.white).cornerRadius(8)
            }
        }
        
        struct ContentBodyCell: View {
            let action: (Measurement.Posture.Body)->Void
            let posture: Measurement.Posture
            var body: some View {
                HStack{
                    Text(LocalizedStringKey("Body position")).foregroundStyle(Color("#415FEE")).font(.system(size: 16))
                    Spacer()
                    ForEach(Measurement.Posture.Body.allCases, id: \.self) { item in
                        Button(action: {
                            action(item)
                        }) {
                            VStack{
                                Image(item.icon)
                                Image("edit_selected").opacity(posture.body == item ? 1.0 : 0.0)
                            }
                        }
                    }
                }.padding(.horizontal, 12).padding(.vertical, 10).background(.white).cornerRadius(8)
            }
        }
        
        struct ContentNoteCell: View {
            @Binding var measure: Measurement
            var body: some View {
                HStack{
                    Text(LocalizedStringKey("Note")).foregroundStyle(Color("#415FEE")).font(.system(size: 16))
                    Spacer()
                    TextField("", text: $measure.note, prompt: Text(LocalizedStringKey("Mabel Figueroa Hattie Fitzgerald Nancy Ball Mabel Figueroa"))).font(.system(size: 12.0)).onReceive(Just(measure.note)) { _ in measure.note = String(measure.note.prefix(100)) }
                }.padding(.horizontal, 12).padding(.vertical, 10).background(.white).cornerRadius(8)
            }
        }
    }
    
    struct ButtonView: View {
        let action: ()->Void
        var body: some View {
            Button(action: action) {
                HStack{
                    Spacer()
                    Text(LocalizedStringKey("OK")).foregroundStyle(.white).padding()
                    Spacer()
                }
            }.background(Color("#3654E6").cornerRadius(26)).padding(.horizontal, 70).padding(.vertical, 20)
        }
    }
}
