//
//  Extensions.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/7/25.
//

import SwiftUI
import SwiftData


#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif


