//
//  HelperProtocol.swift
//  MacCleanerHelper
//
//  Protocol for XPC communication between main app and privileged helper
//

import Foundation

@objc protocol HelperProtocol {
    func deleteFile(atPath path: String, completion: @escaping (Bool, Error?) -> Void)
    func secureDeleteFile(atPath path: String, passes: Int, completion: @escaping (Bool, Error?) -> Void)
    func repairDiskPermissions(completion: @escaping (Bool, Error?) -> Void)
    func runMaintenanceScripts(completion: @escaping (Bool, Error?) -> Void)
    func getVersion(completion: @escaping (String) -> Void)
}

