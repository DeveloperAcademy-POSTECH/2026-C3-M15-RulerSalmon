//
//  SatisfactionLineChart.swift
//
//  Created by chaem on 6/11/26.
//

import SwiftUI

struct SatisfactionLineChart: View {
    let points: [SatisfactionPoint]
    let xAxisLabels: [SatisfactionAxisLabel]
    let showsPointMarkers: Bool
    let highlightsLastPoint: Bool

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                drawHorizontalGrid(in: &context, size: size)
                drawLine(in: &context, size: size)
                drawPointMarkers(in: &context, size: size)
                drawAxisLabels(in: &context, size: size)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private func drawHorizontalGrid(in context: inout GraphicsContext, size: CGSize) {
        for value in [5, 3, 1] {
            let y = chartY(for: CGFloat(value), in: size)
            var path = Path()
            path.move(to: CGPoint(x: chartLeftInset, y: y))
            path.addLine(to: CGPoint(x: plotMaxX(in: size), y: y))
            context.stroke(path, with: .color(Color.gray200), style: StrokeStyle(lineWidth: 1))
        }
    }

    private func drawLine(in context: inout GraphicsContext, size: CGSize) {
        let validPoints = points.enumerated().compactMap { index, point -> (Int, CGFloat)? in
            guard let value = point.value else { return nil }
            return (index, value)
        }

        guard validPoints.count > 1 else { return }

        for pair in zip(validPoints, validPoints.dropFirst()) {
            let previous = pair.0
            let current = pair.1

            guard current.0 == previous.0 + 1 else { continue }

            var path = Path()
            path.move(to: chartPoint(index: previous.0, value: previous.1, in: size))
            path.addLine(to: chartPoint(index: current.0, value: current.1, in: size))
            context.stroke(
                path,
                with: .color(Color.blue500),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            )
        }
    }

    private func drawPointMarkers(in context: inout GraphicsContext, size: CGSize) {
        for (index, point) in points.enumerated() {
            guard let value = point.value else { continue }
            let isLastPoint = index == points.indices.last

            guard showsPointMarkers || (highlightsLastPoint && isLastPoint) else {
                continue
            }

            let center = chartPoint(index: index, value: value, in: size)
            let radius: CGFloat = 3.2
            let rect = CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            context.fill(Path(ellipseIn: rect), with: .color(Color.blue500))
        }
    }

    private func drawAxisLabels(in context: inout GraphicsContext, size: CGSize) {
        for value in [5, 3, 1] {
            let text = context.resolve(
                Text("\(value)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.gray600)
            )
            context.draw(
                text,
                at: CGPoint(x: plotMaxX(in: size) + 12, y: chartY(for: CGFloat(value), in: size)),
                anchor: .leading
            )
        }

        for label in xAxisLabels {
            drawXAxisLabel(label, in: &context, size: size)
        }
    }

    private func drawXAxisLabel(
        _ label: SatisfactionAxisLabel,
        in context: inout GraphicsContext,
        size: CGSize
    ) {
        let lines = label.title.split(separator: "\n").map(String.init)
        let x = chartX(for: label.index, in: size)

        guard lines.count > 1 else {
            let text = context.resolve(
                Text(label.title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.gray600)
            )
            context.draw(
                text,
                at: CGPoint(x: x, y: size.height - 6),
                anchor: .bottom
            )
            return
        }

        let dateText = context.resolve(
            Text(lines[0])
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.gray600)
        )
        let weekdayText = context.resolve(
            Text(lines[1])
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.gray600)
        )

        context.draw(
            dateText,
            at: CGPoint(x: x, y: size.height - 22),
            anchor: .center
        )
        context.draw(
            weekdayText,
            at: CGPoint(x: x, y: size.height - 9),
            anchor: .center
        )
    }

    private func chartPoint(index: Int, value: CGFloat, in size: CGSize) -> CGPoint {
        CGPoint(
            x: chartX(for: index, in: size),
            y: chartY(for: value, in: size)
        )
    }

    private func chartX(for index: Int, in size: CGSize) -> CGFloat {
        guard points.count > 1 else {
            return chartLeftInset + plotWidth(in: size) / 2
        }

        return chartLeftInset + CGFloat(index) / CGFloat(points.count - 1) * plotWidth(in: size)
    }

    private func chartY(for value: CGFloat, in size: CGSize) -> CGFloat {
        let normalizedValue = min(max(value / 5, 0), 1)
        return plotMaxY(in: size) - (normalizedValue * plotHeight(in: size))
    }

    private var chartLeftInset: CGFloat {
        30
    }

    private var chartRightInset: CGFloat {
        42
    }

    private var chartTopInset: CGFloat {
        6
    }

    private var chartBottomInset: CGFloat {
        34
    }

    private func plotWidth(in size: CGSize) -> CGFloat {
        max(size.width - chartLeftInset - chartRightInset, 1)
    }

    private func plotHeight(in size: CGSize) -> CGFloat {
        max(size.height - chartTopInset - chartBottomInset, 1)
    }

    private func plotMaxX(in size: CGSize) -> CGFloat {
        chartLeftInset + plotWidth(in: size)
    }

    private func plotMaxY(in size: CGSize) -> CGFloat {
        chartTopInset + plotHeight(in: size)
    }
}
