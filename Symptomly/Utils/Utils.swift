//
//  Utils.swift
//  Symptomly
//
//  Created by Bastien Villefort on 5/8/25.
//

import Foundation
import UIKit

public class Utils {
    
    public static func formatTimeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    public static func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
