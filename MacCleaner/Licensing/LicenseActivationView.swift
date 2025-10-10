//
//  LicenseActivationView.swift
//  MacCleaner
//

import SwiftUI

struct LicenseActivationView: View {
    @State private var licenseKey: String = ""
    @State private var email: String = ""
    @State private var isActivating = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var licenseManager: LicenseManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "key.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Activate MacCleaner")
                    .font(.system(size: 28, weight: .bold))
                
                Text("Enter your license key to unlock all features")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 30)
            
            // Form
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 350)
                
                TextField("License Key (XXXX-XXXX-XXXX-XXXX)", text: $licenseKey)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 350)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Buttons
            HStack(spacing: 16) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.borderless)
                
                Button(action: activateLicense) {
                    if isActivating {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 100)
                    } else {
                        Text("Activate")
                            .frame(width: 100)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isActivating || licenseKey.isEmpty || email.isEmpty)
            }
            
            // Pricing
            Divider()
                .padding(.vertical)
            
            VStack(spacing: 12) {
                Text("Don't have a license?")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    PricingCard(type: .oneTime)
                    PricingCard(type: .annual)
                    PricingCard(type: .family)
                }
            }
            
            Spacer()
        }
        .frame(width: 600, height: 550)
        .padding()
    }
    
    private func activateLicense() {
        isActivating = true
        errorMessage = nil
        
        Task {
            do {
                try await licenseManager.activateLicense(key: licenseKey, email: email)
                await MainActor.run {
                    isActivating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isActivating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct PricingCard: View {
    let type: LicenseManager.LicenseType
    
    var body: some View {
        VStack(spacing: 8) {
            Text(type.rawValue)
                .font(.caption.bold())
            
            Text(type.price)
                .font(.title3.bold())
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .frame(width: 150, height: 80)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
        )
    }
}

