//
//  MonthlyAnalysisView.swift
//
//  Created by magic3ightball on 6/7/26.
//

import SwiftUI

struct MonthlyAnalysisView: View {
    var body: some View {
        AnalysisView(initialTab: .monthly, navigationTitle: "기간별 인사이트")
    }
}

struct MonthlyAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MonthlyAnalysisView()
        }
    }
}
