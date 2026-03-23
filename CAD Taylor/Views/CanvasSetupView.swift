//
//  CanvasSetupView.swift
//  CAD Taylor
//
//  Created by Peter Homberg on 3/22/26.
//

import SwiftUI

struct CanvasSetupView: View {
    @Binding var showCanvasSetup: Bool
    @Binding var canvasSize: CGSize

    @State private var widthMM: String = ""
    @State private var heightMM: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            Text("Canvas Setup")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Text("Canvas Size (mm)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Width").font(.caption).foregroundColor(.secondary)
                        TextField("Width", text: $widthMM)
                            .frame(width: 80)
                            .textFieldStyle(.roundedBorder)
                    }
                    Text("×").padding(.top, 14)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Height").font(.caption).foregroundColor(.secondary)
                        TextField("Height", text: $heightMM)
                            .frame(width: 80)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }

            Divider()

            HStack {
                Button("Cancel") {
                    showCanvasSetup = false
                }
                .toolbarButton(role: .default)

                Spacer()

                Button("OK") {
                    let w = CGFloat(Double(widthMM)  ?? Double(canvasSize.width  / 72 * 25.4))
                    let h = CGFloat(Double(heightMM) ?? Double(canvasSize.height / 72 * 25.4))
                    canvasSize = CGSize(
                        width:  w / 25.4 * 72,
                        height: h / 25.4 * 72
                    )
                    showCanvasSetup = false
                }
                .toolbarButton(role: .confirm)
                .disabled(widthMM.isEmpty || heightMM.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 260)
        .onAppear {
            let wMM = canvasSize.width  / 72 * 25.4
            let hMM = canvasSize.height / 72 * 25.4
            widthMM  = String(format: "%.0f", wMM)
            heightMM = String(format: "%.0f", hMM)
        }
    }
}
