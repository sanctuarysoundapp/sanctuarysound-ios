// ============================================================================
// StepNavigation.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Views/Components — Step navigation primitives
// Purpose: Step indicator progress bar and Back/Next navigation bar used
//          by the InputEntryView service setup wizard.
// ============================================================================

import SwiftUI


// MARK: - ─── Step Indicator Bar ──────────────────────────────────────────

struct StepIndicatorBar: View {
    let currentStep: SetupStep
    let progress: Double

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(BoothColors.divider)
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(BoothColors.accent)
                        .frame(width: geo.size.width * progress, height: 3)
                        .animation(.spring(response: 0.4), value: progress)
                }
            }
            .frame(height: 3)

            HStack {
                ForEach(SetupStep.allCases) { step in
                    Button { } label: {
                        VStack(spacing: 2) {
                            Image(systemName: step.icon)
                                .font(.system(size: 14, weight: step == currentStep ? .bold : .regular))
                                .foregroundStyle(step == currentStep ? BoothColors.accent : BoothColors.textMuted)
                            Text(step.title)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(step == currentStep ? BoothColors.textPrimary : BoothColors.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Step: \(step.title)")
                    .accessibilityAddTraits(step == currentStep ? .isSelected : [])
                }
            }
        }
        .padding(.bottom, 8)
    }
}


// MARK: - ─── Step Navigation Bar ─────────────────────────────────────────

struct StepNavigationBar: View {
    @ObservedObject var vm: ServiceSetupViewModel

    var body: some View {
        HStack {
            if vm.currentStep != .basics {
                Button {
                    if let prev = SetupStep(rawValue: vm.currentStep.rawValue - 1) {
                        vm.currentStep = prev
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BoothColors.textSecondary)
                }
            }

            Spacer()

            if vm.currentStep != .review {
                Button {
                    if let next = SetupStep(rawValue: vm.currentStep.rawValue + 1) {
                        vm.currentStep = next
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(BoothColors.accent)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(BoothColors.surface)
    }
}
