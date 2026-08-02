import SwiftUI

struct CoveragePresetRow: View {
    @Binding var coverage: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("QUICK PRESETS")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(Color("AppTextSecondary"))

            HStack(spacing: 8) {
                ForEach(CoveragePreset.allCases) { preset in
                    Button {
                        coverage = preset.coverage
                        HapticFeedback.light()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: preset.symbolName)
                                .font(.system(size: 14, weight: .semibold))
                            Text(preset.title.uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .tracking(0.8)
                        }
                        .foregroundStyle(abs(coverage - preset.coverage) < 0.5 ? Color("AppBackground") : Color("AppTextSecondary"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(abs(coverage - preset.coverage) < 0.5 ? Color("AppPrimary") : Color("AppSurface").opacity(0.35))
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .stroke(Color("AppPrimary").opacity(0.4), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ConditionTagPicker: View {
    @Binding var tags: [ConditionTag]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CONDITION TAGS")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(Color("AppTextSecondary"))

            HStack(spacing: 8) {
                ForEach(ConditionTag.allCases) { tag in
                    let selected = tags.contains(tag)
                    Button {
                        if selected {
                            tags.removeAll { $0 == tag }
                        } else {
                            tags.append(tag)
                        }
                        HapticFeedback.soft()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: tag.symbolName)
                                .font(.system(size: 11, weight: .semibold))
                            Text(tag.title.uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .tracking(0.6)
                        }
                        .foregroundStyle(selected ? Color("AppBackground") : Color("AppTextSecondary"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(selected ? Color("AppAccent") : Color("AppSurface").opacity(0.3))
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .stroke(Color("AppAccent").opacity(selected ? 0.8 : 0.35), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ObservationPeriodPicker: View {
    @Binding var period: ObservationPeriod

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TIME OF DAY")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(Color("AppTextSecondary"))

            HStack(spacing: 8) {
                ForEach(ObservationPeriod.allCases) { item in
                    Button {
                        period = item
                        HapticFeedback.light()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: item.symbolName)
                                .font(.system(size: 13, weight: .semibold))
                            Text(item.title.uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .tracking(0.6)
                        }
                        .foregroundStyle(period == item ? Color("AppBackground") : Color("AppTextSecondary"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(period == item ? Color("AppPrimary") : Color("AppSurface").opacity(0.3))
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .stroke(Color("AppPrimary").opacity(0.4), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct LocationField: View {
    @Binding var location: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("LOCATION")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(Color("AppTextSecondary"))
            TextField("City or place (optional)", text: $location)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color("AppSurface").opacity(0.45))
                        .overlay {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(Color("AppPrimary").opacity(0.35), lineWidth: 1)
                        }
                )
                .foregroundStyle(Color("AppTextPrimary"))
        }
    }
}

struct FilterChip: View {
    let title: String
    let selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(0.7)
                .foregroundStyle(selected ? Color("AppBackground") : Color("AppTextSecondary"))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(selected ? Color("AppPrimary") : Color("AppSurface").opacity(0.3))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .stroke(Color("AppPrimary").opacity(0.35), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}
