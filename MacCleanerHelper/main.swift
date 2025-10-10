//
//  main.swift
//  MacCleanerHelper
//
//  Privileged helper tool main entry point
//

import Foundation

let delegate = HelperService()
let listener = NSXPCListener(machServiceName: "com.maccleaner.helper")
listener.delegate = delegate
listener.resume()

RunLoop.current.run()

