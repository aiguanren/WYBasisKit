// 
//  WYCodableAdapter.swift
//  WYBasisKit
//
//  Created by 官人 on 2024/1/22.
//

import Foundation

/// 类型转换错误类型
@frozen public enum WYCodableError: Error {
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

/**
 *  字段适配协议(模型字段经它从解码器取值，取不到时回落默认值而不抛错)
 *
 */
public protocol WYCodableAdapter {
    
    /**
     *  适配出 Bool，取不到或类型不符时回落默认值
     *
     *  @param decoder    解码器
     *
     *  @return 适配出的值
     *
     */
    func adapt(_ decoder: WYDecoder) throws -> Bool
    
    /**
     *  适配出 Int，取不到或类型不符时回落默认值
     *
     *  @param decoder    解码器
     *
     *  @return 适配出的值
     *
     */
    func adapt(_ decoder: WYDecoder) throws -> Int
    
    /**
     *  适配出 UInt，取不到或类型不符时回落默认值
     *
     *  @param decoder    解码器
     *
     *  @return 适配出的值
     *
     */
    func adapt(_ decoder: WYDecoder) throws -> UInt
    
    /**
     *  适配出 CGFloat，取不到或类型不符时回落默认值
     *
     *  @param decoder    解码器
     *
     *  @return 适配出的值
     *
     */
    func adapt(_ decoder: WYDecoder) throws -> CGFloat
    
    /**
     *  适配出 Double，取不到或类型不符时回落默认值
     *
     *  @param decoder    解码器
     *
     *  @return 适配出的值
     *
     */
    func adapt(_ decoder: WYDecoder) throws -> Double
    
    /**
     *  适配出 String，取不到或类型不符时回落默认值
     *
     *  @param decoder    解码器
     *
     *  @return 适配出的值
     *
     */
    func adapt(_ decoder: WYDecoder) throws -> String
    
    /**
     *  可空适配出 Bool，取不到或类型不符时返回 nil
     *
     *  @param decoder    解码器
     *
     *  @return 适配出的值，取不到时为 nil
     *
     */
    func adaptIfPresent(_ decoder: WYDecoder) throws -> Bool?
    
    /**
     *  可空适配出 Int，取不到或类型不符时返回 nil
     *
     *  @param decoder    解码器
     *
     *  @return 适配出的值，取不到时为 nil
     *
     */
    func adaptIfPresent(_ decoder: WYDecoder) throws -> Int?
    
    /**
     *  可空适配出 UInt，取不到或类型不符时返回 nil
     *
     *  @param decoder    解码器
     *
     *  @return 适配出的值，取不到时为 nil
     *
     */
    func adaptIfPresent(_ decoder: WYDecoder) throws -> UInt?
    
    /**
     *  可空适配出 CGFloat，取不到或类型不符时返回 nil
     *
     *  @param decoder    解码器
     *
     *  @return 适配出的值，取不到时为 nil
     *
     */
    func adaptIfPresent(_ decoder: WYDecoder) throws -> CGFloat?
    
    /**
     *  可空适配出 Double，取不到或类型不符时返回 nil
     *
     *  @param decoder    解码器
     *
     *  @return 适配出的值，取不到时为 nil
     *
     */
    func adaptIfPresent(_ decoder: WYDecoder) throws -> Double?
    
    /**
     *  可空适配出 String，取不到或类型不符时返回 nil
     *
     *  @param decoder    解码器
     *
     *  @return 适配出的值，取不到时为 nil
     *
     */
    func adaptIfPresent(_ decoder: WYDecoder) throws -> String?
    
    /**
     *  可空适配出 URL，取不到或类型不符时返回 nil
     *
     *  @param decoder    解码器
     *
     *  @return 适配出的值，取不到时为 nil
     *
     */
    func adaptIfPresent(_ decoder: WYDecoder) throws -> URL?
    
    /**
     *  可空适配出任意 Decodable 类型，取不到或类型不符时返回 nil
     *
     *  @param decoder    解码器
     *
     *  @return 适配出的值，取不到时为 nil
     *
     */
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
