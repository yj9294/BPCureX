//
//  ReminderView.swift
//  BPCureX
//
//  Created by yangjian on 2023/12/15.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct ReminderReducer: Reducer {
    struct State: Equatable {
        @FileHelper(.reminder, defaultValue: ["08:00", "10:00", "12:00", "14:00", "16:00", "18:00", "20:00"])
        var reminders: [String]
        @PresentationState var datePicker: DatePickerReducer.State? = nil
        mutating func remove(_ item: String) {
            reminders = reminders.filter({$0 != item })
            NotificationHelper.shared.removeReminder(item)
        }
        mutating func add(_ item: String) {
            reminders.append(item)
            reminders.sort { i1, i2 in
                i1 < i2
            }
            NotificationHelper.shared.appendReminder(item)
        }
    }
    enum Action: Equatable {
        case pop
        case appear
        case addReminderTapped
        case delete(String)
        case itemDidSelected(String)
        case datePicker(PresentationAction<DatePickerReducer.Action>)
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            if case let .delete(reminder) = action {
                state.remove(reminder)
            }
            if case .addReminderTapped = action {
                state.datePicker = .init(date: Date(), postion: .newReminder, components: .hourAndMinute)
            }
            if case .datePicker(.presented(.ok)) = action {
                let reminder = (state.datePicker?.$date.wrappedValue ?? Date()).time
                state.add(reminder)
                state.datePicker = nil
            }
            if case .datePicker(.presented(.cancel)) = action {
                state.datePicker = nil
            }
            if case .appear = action {
                state.reminders.forEach { item in
                    NotificationHelper.shared.appendReminder(item)
                }
            }
            return .none
        }.ifLet(\.$datePicker, action: /Action.datePicker) {
            DatePickerReducer()
        }
    }
}

struct ReminderView: View {
    let store: StoreOf<ReminderReducer>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                List(viewStore.reminders.indices, id: \.self) { index in
                    Button(action: {
                        viewStore.send(.itemDidSelected(viewStore.reminders[index]))
                    }, label: {
                        HStack{
                            Text(viewStore.reminders[index]).padding(.all, 16).foregroundStyle(.black)
                            Spacer()
                        }
                    }).swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                        Button {
                            viewStore.send(.delete(viewStore.reminders[index]))
                        } label: {
                            Text(LocalizedStringKey("Delete"))
                        }.tint(.red)
                    })
                }
            }.back(LocalizedStringKey(ProfileReducer.State.Item.reminder.title)) {
                viewStore.send(.pop)
            }.right {
                viewStore.send(.addReminderTapped)
            } label: {
                Image("profile_add")
            }.fullScreenCover(store: store.scope(state: \.$datePicker, action: ReminderReducer.Action.datePicker)) { store in
                DatePickerView(store: store)
            }.onAppear(perform: {
                viewStore.send(.appear)
            })
        }
    }
}
