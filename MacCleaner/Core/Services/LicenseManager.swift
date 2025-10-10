//
//  LicenseManager.swift
//  MacCleaner
//

import Foundation
import CryptoKit

class LicenseManager: ObservableObject {
    static let shared = LicenseManager()
    
    @Published var licenseStatus: LicenseStatus = .trial
    @Published var trialDaysRemaining: Int = 7
    @Published var licenseType: LicenseType?
    
    private let trialDuration: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    private let licenseFilePath: URL
    
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("MacCleaner")
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        licenseFilePath = appFolder.appendingPathComponent("license.dat")
    }
    
    enum LicenseStatus {
        case trial
        case trialExpired
        case licensed
        case invalid
    }
    
    enum LicenseType: String, Codable {
        case oneTime = "One-Time Purchase"
        case annual = "Annual Subscription"
        case family = "Family Pack"
        
        var price: String {
            switch self {
            case .oneTime: return "$79.95"
            case .annual: return "$34.95/year"
            case .family: return "$119.95"
            }
        }
    }
    
    struct License: Codable {
        let key: String
        let type: LicenseType
        let email: String
        let activationDate: Date
        let expiryDate: Date?
        let deviceID: String
        let signature: String
    }
    
    // MARK: - License Validation
    
    func validateLicense() {
        // Check for existing license
        if let license = loadLicense() {
            if verifyLicense(license) {
                licenseStatus = .licensed
                licenseType = license.type
                return
            } else {
                licenseStatus = .invalid
                return
            }
        }
        
        // Check trial status
        checkTrialStatus()
    }
    
    private func checkTrialStatus() {
        let defaults = UserDefaults.standard
        
        if let firstLaunchDate = defaults.object(forKey: "firstLaunchDate") as? Date {
            let elapsed = Date().timeIntervalSince(firstLaunchDate)
            let remaining = trialDuration - elapsed
            
            if remaining > 0 {
                trialDaysRemaining = Int(ceil(remaining / (24 * 60 * 60)))
                licenseStatus = .trial
            } else {
                trialDaysRemaining = 0
                licenseStatus = .trialExpired
            }
        } else {
            // First launch
            defaults.set(Date(), forKey: "firstLaunchDate")
            trialDaysRemaining = 7
            licenseStatus = .trial
        }
    }
    
    // MARK: - License Management
    
    func activateLicense(key: String, email: String) async throws {
        // Validate license key format
        guard isValidLicenseFormat(key) else {
            throw LicenseError.invalidFormat
        }
        
        // Generate device ID
        let deviceID = getDeviceID()
        
        // Verify with server (or offline validation)
        let licenseData = try await verifyWithServer(key: key, email: email, deviceID: deviceID)
        
        // Save license
        try saveLicense(licenseData)
        
        // Update status
        await MainActor.run {
            self.licenseStatus = .licensed
            self.licenseType = licenseData.type
        }
    }
    
    func deactivateLicense() throws {
        try? FileManager.default.removeItem(at: licenseFilePath)
        licenseStatus = .trialExpired
        licenseType = nil
    }
    
    // MARK: - Storage
    
    private func loadLicense() -> License? {
        guard let data = try? Data(contentsOf: licenseFilePath) else {
            return nil
        }
        
        return try? JSONDecoder().decode(License.self, from: data)
    }
    
    private func saveLicense(_ license: License) throws {
        let data = try JSONEncoder().encode(license)
        try data.write(to: licenseFilePath)
    }
    
    // MARK: - Verification
    
    private func verifyLicense(_ license: License) -> Bool {
        // Verify device ID matches
        guard license.deviceID == getDeviceID() else {
            return false
        }
        
        // Verify expiry for subscriptions
        if let expiryDate = license.expiryDate {
            guard Date() < expiryDate else {
                return false
            }
        }
        
        // Verify signature
        return verifySignature(license)
    }
    
    private func verifySignature(_ license: License) -> Bool {
        // Implement RSA signature verification
        // This would verify the license was signed by our private key
        let payload = "\(license.key)\(license.email)\(license.deviceID)"
        
        // Placeholder - implement real crypto verification
        return !license.signature.isEmpty
    }
    
    private func isValidLicenseFormat(_ key: String) -> Bool {
        // Format: XXXX-XXXX-XXXX-XXXX
        let pattern = "^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$"
        return key.range(of: pattern, options: .regularExpression) != nil
    }
    
    private func getDeviceID() -> String {
        // Generate unique device identifier
        if let uuid = UserDefaults.standard.string(forKey: "deviceUUID") {
            return uuid
        }
        
        let uuid = UUID().uuidString
        UserDefaults.standard.set(uuid, forKey: "deviceUUID")
        return uuid
    }
    
    private func verifyWithServer(key: String, email: String, deviceID: String) async throws -> License {
        // In production, this would contact a license server
        // For now, create a mock license
        
        // Determine license type from key prefix
        let prefix = String(key.prefix(4))
        let type: LicenseType
        
        switch prefix {
        case let p where p.hasPrefix("OT"):
            type = .oneTime
        case let p where p.hasPrefix("AN"):
            type = .annual
        case let p where p.hasPrefix("FAM"):
            type = .family
        default:
            throw LicenseError.invalidKey
        }
        
        let license = License(
            key: key,
            type: type,
            email: email,
            activationDate: Date(),
            expiryDate: type == .annual ? Date().addingTimeInterval(365 * 24 * 60 * 60) : nil,
            deviceID: deviceID,
            signature: "mock_signature"
        )
        
        return license
    }
}

enum LicenseError: LocalizedError {
    case invalidFormat
    case invalidKey
    case serverError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid license key format"
        case .invalidKey:
            return "Invalid license key"
        case .serverError:
            return "Server error during validation"
        case .networkError:
            return "Network error. Please check your connection."
        }
    }
}

