//
//  CalendarView.swift
//  spark-budget
//
//  Created by Kason Suchow on 10/15/25.
//

import SwiftUI

struct CalendarView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Calendar View")
                    .font(.title)
                Text("Coming soon")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Calendar")
        }
    }
}

#Preview {
    CalendarView()
}
