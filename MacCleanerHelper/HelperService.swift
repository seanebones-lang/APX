//
//  HelperService.swift
//  MacCleanerHelper
//

import Foundation

class HelperService: NSObject, HelperProtocol, NSXPCListenerDelegate {
    func deleteFile(atPath path: String, completion: @escaping (Bool, Error?) -> Void) {
        do {
            try FileManager.default.removeItem(atPath: path)
            completion(true, nil)
        } catch {
            completion(false, error)
        }
    }
    
    func secureDeleteFile(atPath path: String, passes: Int, completion: @escaping (Bool, Error?) -> Void) {
        do {
            // Get file size
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            guard let fileSize = attributes[.size] as? Int else {
                completion(false, NSError(domain: "com.maccleaner.helper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to get file size"]))
                return
            }
            
            // Open file for writing
            guard let fileHandle = FileHandle(forWritingAtPath: path) else {
                completion(false, NSError(domain: "com.maccleaner.helper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to open file"]))
                return
            }
            
            defer {
                try? fileHandle.close()
            }
            
            // Overwrite file with random data multiple times
            for _ in 0..<passes {
                fileHandle.seek(toFileOffset: 0)
                
                let blockSize = 4096
                var remaining = fileSize
                
                while remaining > 0 {
                    let writeSize = min(remaining, blockSize)
                    var randomBytes = [UInt8](repeating: 0, count: writeSize)
                    _ = SecRandomCopyBytes(kSecRandomDefault, writeSize, &randomBytes)
                    
                    let data = Data(randomBytes)
                    fileHandle.write(data)
                    remaining -= writeSize
                }
                
                fileHandle.synchronize()
            }
            
            // Finally, delete the file
            try FileManager.default.removeItem(atPath: path)
            completion(true, nil)
            
        } catch {
            completion(false, error)
        }
    }
    
    func repairDiskPermissions(completion: @escaping (Bool, Error?) -> Void) {
        // Run diskutil commands
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
        task.arguments = ["resetUserPermissions", "/", String(getuid())]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                completion(true, nil)
            } else {
                completion(false, NSError(domain: "com.maccleaner.helper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Disk repair failed"]))
            }
        } catch {
            completion(false, error)
        }
    }
    
    func runMaintenanceScripts(completion: @escaping (Bool, Error?) -> Void) {
        // Run periodic maintenance scripts
        let scripts = ["daily", "weekly", "monthly"]
        
        for script in scripts {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/sbin/periodic")
            task.arguments = [script]
            
            do {
                try task.run()
                task.waitUntilExit()
            } catch {
                completion(false, error)
                return
            }
        }
        
        completion(true, nil)
    }
    
    func getVersion(completion: @escaping (String) -> Void) {
        completion("1.0.0")
    }
    
    // MARK: - NSXPCListenerDelegate
    
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: HelperProtocol.self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }
}

