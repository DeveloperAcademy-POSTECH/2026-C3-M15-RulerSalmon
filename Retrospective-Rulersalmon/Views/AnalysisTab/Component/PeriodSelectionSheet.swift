//
//  PeriodSelectionSheet.swift
//
//  Created by chaem on 6/11/26.
//

import SwiftUI

struct PeriodSelectionSheet: View {
    @Binding var selectedYear: Int
    @Binding var selectedMonth: Int
    let availableRange: PeriodRange
    @Binding var isPresented: Bool

    @State private var displayedYear: Int

    init(
        selectedYear: Binding<Int>,
        selectedMonth: Binding<Int>,
        availableRange: PeriodRange,
        isPresented: Binding<Bool>
    ) {
        _selectedYear = selectedYear
        _selectedMonth = selectedMonth
        self.availableRange = availableRange
        _isPresented = isPresented
        _displayedYear = State(initialValue: selectedYear.wrappedValue)
    }

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color.gray300)
                .frame(width: 42, height: 4)
                .padding(.top, 8)

            HStack {
                Text("기간 선택")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.gray900)

                Spacer()

                Button("완료") {
                    isPresented = false
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.blue600)
                .buttonStyle(.plain)
            }

            HStack {
                yearButton(systemName: "chevron.left", year: displayedYear - 1)

                Text("\(String(displayedYear))년")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.gray900)
                    .frame(maxWidth: .infinity)

                yearButton(systemName: "chevron.right", year: displayedYear + 1)
            }
            .frame(height: 38)
            .background {
                Capsule()
                    .fill(Color.gray50)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(1...12, id: \.self) { month in
                    monthButton(month)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
    }

    private func yearButton(systemName: String, year: Int) -> some View {
        Button {
            guard availableRange.canMove(to: year) else { return }
            displayedYear = year
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(availableRange.canMove(to: year) ? Color.gray600 : Color.gray300)
                .frame(width: 38, height: 38)
        }
        .buttonStyle(.plain)
        .disabled(!availableRange.canMove(to: year))
    }

    private func monthButton(_ month: Int) -> some View {
        let isEnabled = availableRange.isMonthEnabled(year: displayedYear, month: month)
        let isSelected = selectedYear == displayedYear && selectedMonth == month

        return Button {
            guard isEnabled else { return }
            selectedYear = displayedYear
            selectedMonth = month
            isPresented = false
        } label: {
            Text("\(month)월")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(monthTextColor(isEnabled: isEnabled, isSelected: isSelected))
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background {
                    Capsule()
                        .fill(isSelected ? Color.blue50 : Color.gray50)
                }
                .overlay {
                    Capsule()
                        .stroke(isSelected ? Color.blue500 : Color.clear, lineWidth: 1.5)
                }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel("\(displayedYear)년 \(month)월")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func monthTextColor(isEnabled: Bool, isSelected: Bool) -> Color {
        if !isEnabled {
            return Color.gray300
        }

        return isSelected ? Color.blue600 : Color.gray600
    }
}

