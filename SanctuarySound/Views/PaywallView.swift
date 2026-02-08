// ============================================================================
// PaywallView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: In-app purchase paywall sheet for SanctuarySound Pro. Displays
//          the Pro feature list, price, purchase button, and restore link.
//          Designed with BoothColors for dark sound booth environments.
// ============================================================================

import SwiftUI
import StoreKit


// MARK: - ─── Paywall View ─────────────────────────────────────────────────

struct PaywallView: View {
    @ObservedObject var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            BoothColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // ── Dismiss Button ──
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(BoothColors.textMuted)
                        }
                    }
                    .padding(.top, 8)

                    // ── App Icon ──
                    Image("AppIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: BoothColors.accent.opacity(0.3), radius: 12)

                    // ── Header ──
                    VStack(spacing: 6) {
                        Text("UNLOCK PRO")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .tracking(3)
                            .foregroundStyle(BoothColors.textPrimary)

                        Text("Full toolkit for every Sunday")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(BoothColors.textSecondary)
                    }

                    // ── Feature List ──
                    VStack(spacing: 0) {
                        proFeatureRow(
                            icon: "slider.horizontal.3",
                            title: "Unlimited Channels",
                            description: "Full 20+ channel services with no restrictions"
                        )
                        proFeatureDivider
                        proFeatureRow(
                            icon: "waveform.path.ecg",
                            title: "Full EQ, Compression & HPF",
                            description: "Key-aware parametric EQ, compressor settings, and high-pass filters"
                        )
                        proFeatureDivider
                        proFeatureRow(
                            icon: "speaker.wave.2.fill",
                            title: "SPL Reports & Calibration",
                            description: "Unlimited monitoring, session reports with breach logging"
                        )
                        proFeatureDivider
                        proFeatureRow(
                            icon: "doc.text.magnifyingglass",
                            title: "CSV Import & Analysis",
                            description: "Import mixer state and compare vs. ideal settings"
                        )
                        proFeatureDivider
                        proFeatureRow(
                            icon: "person.2.fill",
                            title: "Unlimited Saved Profiles",
                            description: "Save all your vocalist profiles, inputs, and services"
                        )
                    }
                    .background(BoothColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // ── Price Badge ──
                    if let product = purchaseManager.products.first {
                        Text(product.displayPrice)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundStyle(BoothColors.textPrimary)

                        Text("One-time purchase. Yours forever.")
                            .font(.system(size: 12))
                            .foregroundStyle(BoothColors.textSecondary)
                    }

                    // ── Purchase Button ──
                    Button {
                        Task { await purchaseManager.purchase() }
                    } label: {
                        HStack(spacing: 8) {
                            if purchaseManager.purchaseState.isLoading {
                                ProgressView()
                                    .tint(BoothColors.background)
                            }
                            Text(purchaseButtonLabel)
                                .font(.system(size: 16, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundStyle(BoothColors.background)
                        .background(BoothColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(purchaseManager.purchaseState.isLoading)

                    // ── Error Message ──
                    if case .failed(let message) = purchaseManager.purchaseState {
                        Text(message)
                            .font(.system(size: 12))
                            .foregroundStyle(BoothColors.accentDanger)
                            .multilineTextAlignment(.center)
                    }

                    // ── Restore Link ──
                    Button {
                        Task { await purchaseManager.restore() }
                    } label: {
                        Text("Restore Purchase")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BoothColors.textSecondary)
                            .underline()
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
            }
        }
        .preferredColorScheme(.dark)
        .task { await purchaseManager.loadProducts() }
        .onChange(of: purchaseManager.purchaseState) { _, newState in
            if newState == .purchased {
                dismiss()
            }
        }
    }


    // MARK: - ─── Subviews ─────────────────────────────────────────────────

    private func proFeatureRow(
        icon: String,
        title: String,
        description: String
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(BoothColors.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(BoothColors.textPrimary)
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(BoothColors.textSecondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var proFeatureDivider: some View {
        Rectangle()
            .fill(BoothColors.divider)
            .frame(height: 1)
            .padding(.leading, 62)
    }

    private var purchaseButtonLabel: String {
        switch purchaseManager.purchaseState {
        case .purchasing: return "Purchasing..."
        case .restoring: return "Restoring..."
        case .pending: return "Pending Approval"
        default: return "Unlock SanctuarySound Pro"
        }
    }
}


// MARK: - ─── Preview ─────────────────────────────────────────────────────

#Preview("Paywall") {
    PaywallView(purchaseManager: PurchaseManager())
}
