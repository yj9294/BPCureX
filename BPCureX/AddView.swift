//
//  AddView.swift
//  BPCureX
//
//  Created by yangjian on 2023/12/12.
//

import Foundation
import SwiftUI
import UIKit
import ComposableArchitecture

struct AddReducer: Reducer {
    struct State: Equatable {
        var path: StackState<PathReducer.State> = .init()
        var status: Status = .new
        @BindingState var measure: Measurement = .init()
        
    }
    enum Action: BindableAction, Equatable {
        case path(StackAction<PathReducer.State, PathReducer.Action>)
        case dismiss
        case pushEditView
        case binding(BindingAction<State>)
    }
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce{ state, action in
            if case .pushEditView = action {
                state.pushEditView()
            }
            if case .path(.element(id: _, action: .edit(.pop))) = action {
                state.popEditView()
            }
            return .none
        }.forEach(\.path, action: /Action.path) {
            PathReducer()
        }
    }
    
    struct PathReducer: Reducer {
        enum State: Equatable {
            case edit(EditReducer.State)
        }
        enum Action: Equatable {
            case edit(EditReducer.Action)
        }
        var body: some Reducer<State, Action> {
            Reduce{ state, action in
                return .none
            }
            Scope(state: /State.edit, action: /Action.edit) {
                EditReducer()
            }
        }
    }
}

extension AddReducer.State {
    enum Status {
        case new, edit
        var title: String {
            switch self {
            case .new:
                return "New Measurement"
            case .edit:
                return "Edit"
            }
        }
    }
    enum Item: String {
        case sys, dia, pulse
        var title: String {
            return self.rawValue.uppercased()
        }
        var unit: String {
            switch self {
            case .sys, .dia:
                return "mmHg"
            case .pulse:
                return "BPM"
            }
        }
    }
    mutating func pushEditView() {
        path.append(.edit(.init(status: status, measure: measure)))
    }
    mutating func popEditView() {
        path.removeAll()
    }
}


struct AddView: View {
    let store: StoreOf<AddReducer>
    var body: some View {
        NavigationStackStore(store.scope(state: \.path, action: {.path($0)})) {
            RootView(store: store)
        } destination: {
            switch $0 {
            case .edit:
                CaseLet(/AddReducer.PathReducer.State.edit, action: AddReducer.PathReducer.Action.edit, then: EditView.init(store:))
            }
        }
    }
    
    struct RootView: View {
        let store: StoreOf<AddReducer>
        var body: some View {
            WithViewStore(store, observe: {$0}) { viewStore in
                VStack(spacing: 52){
                    ScalView(value: viewStore.$measure.systolic, item: .sys)
                    ScalView(value: viewStore.$measure.diastolic, item: .dia)
                    ScalView(value: viewStore.$measure.pulse, item: .pulse)
                    ButtonView {
                        viewStore.send(.pushEditView)
                    }
                    Spacer()
                }.back(LocalizedStringKey(viewStore.status.title)) {
                    viewStore.send(.dismiss)
                }
            }
        }
    }
    
    
    struct ScalView: View {
        @Binding var value: Int
        var item: AddReducer.State.Item
        var body: some View {
            VStack{
                ZStack{
                    HStack{
                        Text(LocalizedStringKey(item.title)).foregroundStyle(Color("#4C69F6"))
                        Spacer()
                    }.padding(.horizontal, 16)
                    HStack{
                        Spacer()
                        Text("\(value)").multilineTextAlignment(.center)
                        Spacer()
                    }
                }
                ScaleView(index: $value).frame(height: 44)
            }
        }
    }
    
    struct ButtonView: View {
        let action: ()->Void
        var body: some View {
            Button(action: action) {
                Text(LocalizedStringKey("Continue")).font(.system(size: 16.0)).padding(.vertical, 15).padding(.horizontal, 80)
            }.background(Image("tracker_button_bg")).foregroundStyle(.white)
        }
    }
}

struct ScaleView: UIViewRepresentable {
    @Binding var index: Int // 30 ~ 250
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> some UIView {
        let view =  UIScaleView(index)
        view.delegate = context.coordinator
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    
    class Coordinator: NSObject, UIScaleDelegate {
        var preview: ScaleView
        var delegate: UIScaleDelegate? = nil
        init(_ view: ScaleView) {
            preview = view
        }
        
        func didSelected(index: Int) {
            preview.$index.wrappedValue = index
        }
    }
}

protocol UIScaleDelegate {
    func didSelected(index: Int)
}

class UIScaleView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var index: Int = 0
    var delegate: UIScaleDelegate? = nil
    
    init(_ index: Int) {
        super.init(frame: .zero)
        self.index = index
        self.addSubview(collection)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.collection.setContentOffset(CGPoint(x: 7 * (index - 56), y: 0), animated: false)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collection.frame = self.bounds
        collection.contentInset = UIEdgeInsets(top: 0, left: self.bounds.width / 2.0 , bottom: 0, right: self.bounds.width / 2.0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 221
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 1.0, height: 44)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 6.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 6.0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ScaleCell", for: indexPath)
        if let cell = cell as? UIScaleCell {
            cell.index = indexPath.row + 30
        }
        return cell
    }
    
    lazy var collection: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        let view = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.delegate = self
        view.dataSource = self
        view.register(UIScaleCell.classForCoder(), forCellWithReuseIdentifier: "ScaleCell")
        return view
    }()
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let x = ceil(collection.contentOffset.x  / 7.0)
        index = Int(x) + 56
        debugPrint("\(index)")
        delegate?.didSelected(index: index)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let x = ceil(collection.contentOffset.x  / 7.0)
        index = Int(x) + 56
        debugPrint("\(index)")
        delegate?.didSelected(index: index)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        
    }
}

class UIScaleCell: UICollectionViewCell {
    
    lazy var scaleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor(named: "#A9B5F0")
        return label
    }()
    
    lazy var label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.adjustsFontSizeToFitWidth = true
        label.textColor = UIColor(named: "#A9B5F0")
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(scaleLabel)
        addSubview(label)
        label.textAlignment = .center
        label.clipsToBounds = false
        label.frame = CGRect(x: -15, y: 26, width: 30, height: 18)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var index: Int = 30 {
        didSet {
            if index % 10 == 0 {
                label.text = "\(index)"
                label.isHidden = false
            } else {
                label.isHidden = true
            }
            scaleLabel.frame = CGRect(x: 0, y: (index % 10 == 0) ? 0 : 10, width: 1, height: (index % 10 == 0) ? 21 : 11)
        }
    }
}
