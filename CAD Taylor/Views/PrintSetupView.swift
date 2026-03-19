//
//  PrintSetupView.swift
//  CAD Taylor
//
//  Created by Peter Homberg on 3/19/26.
//

import SwiftUI

struct PrintSetupView: View {
    let canvasSize: CGSize
    @Binding var selectedPaper: PaperSize
    let onExport: (PageLayout) -> Void

    private var layout: PageLayout {
        PageLayout(paperSize: selectedPaper.size, canvasSize: canvasSize)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Print Setup")
                .font(Font.headline.weight(.semibold))

            Picker("Paper Size", selection: $selectedPaper) {
                ForEach(PaperSize.allCases, id: \.self) { paper in
                    Text(paper.rawValue).tag(paper)
                }
            }
            .pickerStyle(.segmented)

            // Page count summary
            HStack(spacing: 20) {
                VStack {
                    Text("\(layout.totalPages)")
                        .font(.system(size: 32, weight: .light))
                    Text("Total pages")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                VStack {
                    Text("\(layout.columns) × \(layout.rows)")
                        .font(.system(size: 32, weight: .light))
                    Text("Columns × Rows")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)

            // Page grid preview
            PageGridPreview(layout: layout)
                .frame(height: 200)

            Text("Pages overlap by 10pt for alignment when gluing.")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Button("Cancel") { onExport(layout) }
                    .toolbarButton(role: .default)
                Spacer()
                Button("Export PDF") { onExport(layout) }
                    .toolbarButton(role: .confirm)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}
