//
//  PrivilegeManager.swift
//  MacCleaner
//
//  Manages communication with privileged helper tool for system-level operations
//

import Foundation
import ServiceManagement

class PrivilegeManager {
    static let shared = PrivilegeManager()
    
    private var helperConnection: NSXPCConnection?
    private let helperID = "com.maccleaner.helper"
    
    private init() {}
    
    // MARK: - Helper Status
    
    func checkHelperStatus() {
        // Check if helper is installed and running
        let helperURL = URL(fileURLWithPath: "/Library/PrivilegedHelperTools/\(helperID)")
        let isInstalled = FileManager.default.fileExists(atPath: helperURL.path)
        
        if !isInstalled {
            print("Helper tool not installed")
        }
    }
    
    func installHelper() async throws {
        // Install helper using SMJobBless
        var authRef: AuthorizationRef?
        let status = AuthorizationCreate(nil, nil, [], &authRef)
        
        guard status == errAuthorizationSuccess else {
            throw PrivilegeError.authorizationFailed
        }
        
        defer {
            if let authRef = authRef {
                AuthorizationFree(authRef, [])
            }
        }
        
        // Register helper tool
        var error: Unmanaged<CFError>?
        let success = SMJobBless(
            kSMDomainSystemLaunchd,
            helperID as CFString,
            authRef,
            &error
        )
        
        if !success {
            if let error = error?.takeRetainedValue() {
                throw PrivilegeError.installationFailed(error as Error)
            }
            throw PrivilegeError.installationFailed(NSError(domain: "com.maccleaner", code: -1))
        }
    }
    
    // MARK: - XPC Connection
    
    private func getHelperConnection() -> NSXPCConnection {
        if let connection = helperConnection {
            return connection
        }
        
        let connection = NSXPCConnection(machServiceName: helperID, options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
        
        connection.invalidationHandler = {
            self.helperConnection = nil
        }
        
        connection.interruptionHandler = {
            self.helperConnection = nil
        }
        
        connection.resume()
        self.helperConnection = connection
        
        return connection
    }
    
    // MARK: - Privileged Operations
    
    func deleteFile(at path: String) async throws {
        let connection = getHelperConnection()
        
        return try await withCheckedThrowingContinuation { continuation in
            let helper = connection.remoteObjectProxyWithErrorHandler { error in
                continuation.resume(throwing: error)
            } as? HelperProtocol
            
            helper?.deleteFile(atPath: path) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? PrivilegeError.operationFailed)
                }
            }
        }
    }
    
    func secureDelete(path: String, passes: Int = 7) async throws {
        let connection = getHelperConnection()
        
        return try await withCheckedThrowingContinuation { continuation in
            let helper = connection.remoteObjectProxyWithErrorHandler { error in
                continuation.resume(throwing: error)
            } as? HelperProtocol
            
            helper?.secureDeleteFile(atPath: path, passes: passes) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? PrivilegeError.operationFailed)
                }
            }
        }
    }
    
    func repairPermissions() async throws {
        let connection = getHelperConnection()
        
        return try await withCheckedThrowingContinuation { continuation in
            let helper = connection.remoteObjectProxyWithErrorHandler { error in
                continuation.resume(throwing: error)
            } as? HelperProtocol
            
            helper?.repairDiskPermissions { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? PrivilegeError.operationFailed)
                }
            }
        }
    }
}

enum PrivilegeError: LocalizedError {
    case authorizationFailed
    case installationFailed(Error)
    case operationFailed
    case helperNotInstalled
    
    var errorDescription: String? {
        switch self {
        case .authorizationFailed:
            return "Authorization failed"
        case .installationFailed(let error):
            return "Helper installation failed: \(error.localizedDescription)"
        case .operationFailed:
            return "Operation failed"
        case .helperNotInstalled:
            return "Helper tool is not installed"
        }
    }
}

