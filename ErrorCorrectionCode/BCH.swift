//
//  BCH.swift
//  ErrorCorrectionCode
//
//  Created by Pofat Tseng on 2021/1/26.
//

import Foundation

// XXX: Final result will be 15-bit in length, so UInt16 seems to be a good choice.
typealias Format = UInt16

extension Format {
    /// Get the Hamming distance from self to "0"
    var hammingWeight: Int {
        var source = self
        var weight: UInt16 = 0
        while source > 0 {
            weight += source & 1
            source >>= 1
        }
        return Int(weight)
    }

    var printedForm: String {
        return pad(String(self, radix: 2), toSize: 15)
    }
}

// A mask for decode and encode
private let generatorMask: Format = 0b10100110111

/// Data structure of formatting information, which includes: error correction code level and mask type.
/// The binary presentation is in the format:
/// |  4 -- 3   | 2 -- 1 -- 0 |
/// | ECL level |   Mask Type |
///
/// For example, a formatting information with M level ECL and mask type 011 will be: 0b00011
struct Formatting: CustomStringConvertible {
    enum ErrorCorrectionLevel: Int {
        case L = 0b01
        case M = 0b00
        case Q = 0b11
        case H = 0b10
    }

    // Check pattern image here: https://upload.wikimedia.org/wikipedia/commons/c/c8/QR_Code_Mask_Patterns.svg
    // Use a~h to replace mask 000 ~ 111
    enum Mask: Int {
        case a, b, c, d, e, f, g, h
    }

    let ecl: ErrorCorrectionLevel
    let mask: Mask

    // This code only takes 5 bit. However we still use UInt16 for less type conversion
    var code: Format {
        return Format(ecl.rawValue<<3 + mask.rawValue)
    }

    var description: String {
        return pad(String(code, radix: 2), toSize: 5)
    }
}

/// Valide if format is not corrupted. Returing a non-zero value means the format code is corrupted.
/// - Parameter format: Target code to be verified.
/// - Returns: Indicated if it's corrupted. 0 means correct format code.
func validate(_ format: Format) -> Format {
    var result = format
    for index in stride(from: 4, through: 0, by: -1) {
        if format & (1 << (index + 10)) != 0 {
            result = result ^ (generatorMask << index)
        }
    }
    return result
}

/// Encode with generator mask
/// - Parameter formatting: Formatting information
/// - Returns: Encoded format code
func encode(_ formatting: Formatting) -> Format {
    let format = formatting.code
    return encode(format)
}

func encode(_ format: Format) -> Format {
    return (format<<10)^(validate(format<<10))
}

/// Decode from formatted code and try to correct if it's corrupted.
/// - Parameter format: Received format
/// - Returns: Decoding result
func tryDecode(_ format: Format) -> DecodeResult {
    var bestAnswer: DecodeResult = .failure
    var minDistance = 15

    // 32 = 2^5 for formatting information is 5 bit.
    // We brute-forcely search all 32 cases
    for fmt: Format in 0..<32 {
        let encodedCode = encode(fmt)
        let distance = (format^encodedCode).hammingWeight
        if distance < minDistance {
            minDistance = distance
            bestAnswer = .success(fmt)
        } else if distance == minDistance {
            bestAnswer = .failure
        }
    }
    return bestAnswer
}

enum DecodeResult {
    case failure
    case success(UInt16)
}

extension DecodeResult: CustomStringConvertible {
    var description: String {
        switch self {
        case .failure:
            return "Not able to decode"
        case .success(let result):
            return "The decoded format is \(pad(String(result, radix: 2), toSize: 5))"
        }
    }
}

/// Fill prefix 0 to target bit size
/// - Parameters:
///   - string: Target string in binary format
///   - toSize: Target size
/// - Returns: String with prefix "0"
func pad(_ string : String, toSize: Int) -> String {
    var padded = string
    for _ in 0..<(toSize - string.count) {
        padded = "0" + padded
    }
    return padded
}

/// Choose one random bit and invert it
/// - Parameter format: Target format code
/// - Returns: Corrupted format code
func makeRandomDirty(_ format: Format) -> Format {
    let index = (0..<15).randomElement()!
    return format ^ (1 << index)
}
