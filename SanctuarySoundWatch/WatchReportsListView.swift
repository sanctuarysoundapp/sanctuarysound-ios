// ============================================================================
// WatchReportsListView.swift
// SanctuarySound Watch — SPL Monitor Companion
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Full list of past SPL session reports on the Watch.
// ============================================================================

import SwiftUI


// MARK: - ─── Watch Reports List ─────────────────────────────────────────────

struct WatchReportsListView: View {
    let reports: [SPLSessionReport]

    var body: some View {
        Group {
            if reports.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 24))
                        .foregroundStyle(WatchColors.textMuted)
                    Text("No Reports Yet")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(WatchColors.textSecondary)
                }
            } else {
                List(reports) { report in
                    NavigationLink {
                        WatchReportDetailView(report: report)
                    } label: {
                        WatchReportRow(report: report)
                    }
                }
            }
        }
        .navigationTitle("Reports")
    }
}
