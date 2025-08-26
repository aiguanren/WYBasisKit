// 
//  WYCodableAdapter.swift
//  WYBasisKit
//
//  Created by 官人 on 2024/1/22.
//

import Foundation

/// 类型转换错误类型
public enum WYCodableError: Error {
    /// Model解码错误
    case modelDecodableError
    /// String转Dictionary错误
    case stringToDictionaryError
    /// String转Array错误
    case stringToArrayError
    /// String转Data错误
    case stringToDataError
    /// Model转String错误
    case modelToStringError
    /// Model转Dictionary错误
    case modelToDictionaryError
    /// Model转Array错误
    case modelToArrayError
    /// Model转Data错误
    case modelToDataError
    /// Dictionary转String错误
    case dictionaryToStringError
    /// Dictionary转Data错误
    case dictionaryToDataError
    /// Array转String错误
    case arrayToStringError
    /// Array转Data错误
    case arrayToDataError
    /// Data转String错误
    case dataToStringError
    /// Data转Dictionary错误
    case dataToDictionaryError
    /// Data转Array错误
    case dataToArrayError
}

public protocol WYCodableAdapter {
    
    func adapt(_ decoder: WYDecoder) throws -> Bool
    
    func adapt(_ decoder: WYDecoder) throws -> Int
    
    func adapt(_ decoder: WYDecoder) throws -> UInt
    
    func adapt(_ decoder: WYDecoder) throws -> CGFloat
    
    func adapt(_ decoder: WYDecoder) throws -> Double
    
    func adapt(_ decoder: WYDecoder) throws -> String
    
    func adaptIfPresent(_ decoder: WYDecoder) throws -> Bool?
    
    func adaptIfPresent(_ decoder: WYDecoder) throws -> Int?
    
    func adaptIfPresent(_ decoder: WYDecoder) throws -> UInt?
    
    func adaptIfPresent(_ decoder: WYDecoder) throws -> CGFloat?
    
    func adaptIfPresent(_ decoder: WYDecoder) throws -> Double?
    
    func adaptIfPresent(_ decoder: WYDecoder) throws -> String?
    
    func adaptIfPresent(_ decoder: WYDecoder) throws -> URL?
    
    func adaptIfPresent<T: Decodable>(_ decoder: WYDecoder) throws -> T?
}

public extension WYCodableAdapter {
    
    @inline(__always)
    func adapt(_ decoder: WYDecoder) throws -> Bool {
        return Bool.defaultValue
    }
    
    @inline(__always)
    func adapt(_ decoder: WYDecoder) throws -> Int {
        guard !decoder.decodeNil() else { return Int.defaultValue }
        
        guard let stringValue = try decoder.decodeIfPresent(String.self) else {
            return Int.defaultValue
        }
        
        return Int(stringValue) ?? Int.defaultValue
    }
    
    @inline(__always)
    func adapt(_ decoder: WYDecoder) throws -> UInt {
        guard !decoder.decodeNil() else { return UInt.defaultValue }
        
        guard let stringValue = try decoder.decodeIfPresent(String.self) else {
            return UInt.defaultValue
        }
        
        return UInt(stringValue) ?? UInt.defaultValue
    }
    
    @inline(__always)
    func adapt(_ decoder: WYDecoder) throws -> CGFloat {
        guard !decoder.decodeNil() else { return CGFloat.defaultValue }
        
        guard let stringValue = try decoder.decodeIfPresent(String.self) else {
            return CGFloat.defaultValue
        }
        
        guard let floatValue: Float = Float(stringValue) else {
            return CGFloat.defaultValue
        }
        
        return CGFloat(floatValue)
    }
    
    @inline(__always)
    func adapt(_ decoder: WYDecoder) throws -> Double {
        guard !decoder.decodeNil() else { return Double.defaultValue }
        
        guard let stringValue = try decoder.decodeIfPresent(String.self) else {
            return Double.defaultValue
        }
        
        return Double(stringValue) ?? Double.defaultValue
    }
    
    @inline(__always)
    func adapt(_ decoder: WYDecoder) throws -> String {
        guard !decoder.decodeNil() else { return String.defaultValue }
        
        return String(describing: decoder.topContainer)
    }
}
