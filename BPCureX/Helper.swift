//
//  Helper.swift
//  BPCureX
//
//  Created by yangjian on 2023/12/12.
//

import Foundation
import SwiftUI

extension Date {
    var detail: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMdd hh:mma"
        return formatter.string(from: self)
    }
    
    var day: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: self)
    }
    
    var day1: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyy-MM-dd"
        return formatter.string(from: self)
    }
    
    var unitDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        return formatter.string(from: self)
    }
    
    var exactlyDay: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let string = formatter.string(from: self)
        let exactlyDay = formatter.date(from: string) ?? Date()
        return exactlyDay.addingTimeInterval(.day - 1) // 23:59:59
    }
    
    var time: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    var dateAndTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: self)
    }
}

extension View {
    var shadow: some View {
        self.modifier(ShadowModifier(cornerRadius: 8))
    }
    func shadow(_ cornerRadius: Double) -> some View {
        self.modifier(ShadowModifier(cornerRadius: cornerRadius))
    }
    
    func back(_ title: LocalizedStringKey = "", action: @escaping ()->Void) -> some View {
        self.modifier(NavigationBackModifier(action: action, title: title))
    }
    
    func right<Label>(_ action: @escaping ()->Void, @ViewBuilder label: @escaping () -> Label) -> some View where Label: View {
        self.modifier(NavigationRightModifier(action: action, label: label))
    }
}

struct ShadowModifier: ViewModifier {
    let cornerRadius: Double
    func body(content: Content) -> some View {
        content.background(Color.white.cornerRadius(cornerRadius).shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2))
    }
}

struct NavigationBackModifier: ViewModifier {
    let action:()->Void
    let title: LocalizedStringKey
    func body(content: Content) -> some View {
        content
            .background(Color("#F3F8FB"))
            .navigationBarBackButtonHidden()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: action) {
                        HStack{
                            Image("back")
                            Text(title).foregroundStyle(.black)
                        }
                    }
                }
            }
    }
}

struct NavigationRightModifier<Label>: ViewModifier where Label: View {
    let action:()->Void
    @ViewBuilder let label: ()-> Label
    func body(content: Content) -> some View {
        content
            .background(Color("#F3F8FB"))
            .navigationBarBackButtonHidden()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: action) {
                        label()
                    }
                }
            }
    }
}

extension TimeInterval {
    static let weak = 7 * 24 * 3600.0
    static let day = 24 * 3600.0
}

struct BackgroundClearView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

extension LocalizedStringKey {

    // This will mirror the `LocalizedStringKey` so it can access its
    // internal `key` property. Mirroring is rather expensive, but it
    // should be fine performance-wise, unless you are
    // using it too much or doing something out of the norm.
    var stringKey: String? {
        Mirror(reflecting: self).children.first(where: { $0.label == "key" })?.value as? String
    }
}

extension String {
    static func localizedString(for key: String,
                                locale: Locale = .current) -> String {
        
        var language = locale.language.languageCode?.identifier
        if language == "pt" {
            language = "pt-PT"
        }
        let path = Bundle.main.path(forResource: language, ofType: "lproj")!
        let bundle = Bundle(path: path)!
        let localizedString = NSLocalizedString(key, bundle: bundle, comment: "")
        
        return localizedString
    }
}

@propertyWrapper
struct FileHelper<T: Codable> where T: Equatable {
    var value: T
    let key: String
    let defaultValue: T
    init(_ key: FileKey, defaultValue: T) {
        self.key = key.rawValue
        self.defaultValue = defaultValue
        self.value = UserDefaults.standard.getObject(T.self, forKey: key.rawValue) ?? defaultValue
    }
    
    var wrappedValue: T {
        set  {
            value = newValue
            UserDefaults.standard.setObject(value, forKey: key)
            UserDefaults.standard.synchronize()
        }
        
        get { value }
    }
    
    static func getObject(_ type: T.Type, forKey key: FileKey) -> T? {
        return UserDefaults.standard.getObject(type, forKey: key.rawValue)
    }

}

extension FileHelper: Equatable {
    static func == (lhs: FileHelper<T>, rhs: FileHelper<T>) -> Bool {
        lhs.value == rhs.value
    }
}


extension UserDefaults {
    func setObject<T: Codable>(_ object: T?, forKey key: String) {
        let encoder = JSONEncoder()
        guard let object = object else {
            debugPrint("[US] object is nil.")
            self.removeObject(forKey: key)
            return
        }
        guard let encoded = try? encoder.encode(object) else {
            debugPrint("[US] encoding error.")
            return
        }
        self.setValue(encoded, forKey: key)
    }
    
    func getObject<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = self.data(forKey: key) else {
            debugPrint("[US] data is nil for \(key).")
            return nil
        }
        guard let object = try? JSONDecoder().decode(type, from: data) else {
            debugPrint("[US] decoding error.")
            return nil
        }
        return object
    }
}

enum FileKey: String {
    case language, measures, duration, reminder, guide, disclaimer
}
