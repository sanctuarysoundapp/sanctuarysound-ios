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
        List(reports) { report in
            NavigationLink {
                WatchReportDetailView(report: report)
            } label: {
                WatchReportRow(report: report)
            }
        }
        .navigationTitle("Reports")
    }
}
