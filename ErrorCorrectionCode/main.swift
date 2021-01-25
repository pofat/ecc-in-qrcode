//
//  main.swift
//  ErrorCorrectionCode
//
//  Created by Pofat Tseng on 2021/1/24.
//

import Foundation

// MARK: Demo BCH error correction code

let f1 = Formatting(ecl: .M, mask: .d)
// Original formatting information: 0b00011
print("Formatting info: \(f1)")

let encodedCode = encode(f1)

print("Is \(encodedCode.printedForm) valid format code? \(validate(encodedCode) == 0)")

// let's corrupt 1 bit at a random position
let corruptedCode = makeRandomDirty(encodedCode)

print("Is \(corruptedCode.printedForm) valid format code? \(validate(corruptedCode) == 0)")

// Try to decode and correct corrupted bit(s). Supposed to be 0b00011
print("Original formatting information is \(tryDecode(corruptedCode))")
