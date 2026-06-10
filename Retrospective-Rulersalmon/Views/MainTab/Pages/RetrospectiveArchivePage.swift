//
//  RetrospectiveArchivePage.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/11/26.
//

import SwiftUI

struct RetrospectiveArchiveView: View {
    let items: [RetrospectiveItem]
    let onSelectItem: (RetrospectiveItem) -> Void
    @State private var selectedMonth: Int

    init(items: [RetrospectiveItem], onSelectItem: @escaping (RetrospectiveItem) -> Void) {
        self.items = items
        self.onSelectItem = onSelectItem
        _selectedMonth = State(initialValue: items.first?.monthValue ?? Calendar.current.component(.month, from: .now))
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea(.all)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 8) {
                            ForEach(1...12, id: \.self) { month in
                                SelectableChip(
                                    label: "\(month)월",
                                    isSelected: selectedMonth == month
                                ) {
                                    selectedMonth = month
                                }
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    LazyVStack(spacing: 16) {
                        ForEach(filteredItems) { item in
                            RetrospectiveArchiveCard(
                                item: item,
                                onTap: { onSelectItem(item) }
                            )
                        }
                    }
                }
                .padding(.horizontal, MainPageLayout.screenPadding)
                .padding(.top, 16)
            }
        }
        .navigationTitle("지난 회고 보기")
    }

    private var filteredItems: [RetrospectiveItem] {
        items.filter { $0.monthValue == selectedMonth }
    }
}

struct RetrospectiveArchiveView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RetrospectiveArchiveView(
                items: MainPageContent.mock.retrospectives,
                onSelectItem: { _ in }
            )
        }
    }
}

private extension RetrospectiveItem {
    var monthValue: Int {
        let parts = date.split(separator: "/")
        guard let month = parts.first, let value = Int(month) else { return 1 }
        return value
    }
}
