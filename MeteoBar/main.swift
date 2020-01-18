//
//  main.swift
//  MeteoBar
//
//  Created by Mike Manzo on 11/2/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa

let delegate = AppDelegate() //alloc main app's delegate class
NSApplication.shared.delegate = delegate //set as app's delegate

let ret = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
