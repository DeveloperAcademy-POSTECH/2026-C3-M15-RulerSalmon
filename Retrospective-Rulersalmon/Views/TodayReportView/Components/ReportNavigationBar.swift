//
//  ReportNavigationBar.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/11/26.
//

import SwiftUI

struct ReportNavigationBar: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.gray900)
                    .frame(width: 40, height: 40)
                    .background {
                        Circle()
                            .fill(Color.white)
                            .shadow(color: Color.gray300.opacity(0.35), radius: 12, x: 0, y: 6)
                    }
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.gray900)

            Spacer()

            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, ReportLayout.screenPadding)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

struct ReportNavigationBar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack {
                ReportNavigationBar(title: "오늘의 회고", onBack: {})
                Spacer()
            }
        }
    }
}
