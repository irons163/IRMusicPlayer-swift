//
//  UIColor+Helper.swift
//  IRMusicPlayer-swift
//
//  Created by Phil on 2021/2/18.
//  Copyright © 2021 Phil. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    class func colorWithColorCodeString(_ colorString: String) -> UIColor {
        let color: UnsafeMutablePointer<UInt64> = UnsafeMutablePointer.init(bitPattern: 0)!
        let scanner: Scanner = Scanner.init(string: colorString)
        
        //    [scanner setScanLocation:1]; // bypass '#' character
        scanner.scanHexInt64(color)
        
    //    NSLog(@"%u",((color >> 24) & 0xFF));
        if(colorString.count == 6){
            return UIColor.colorWithRGB(color.pointee)
        }else{
            return UIColor.colorWithARGB(color.pointee)
        }
    }
    
    class func colorWithRGB(_ color: UInt64) -> UIColor {
        return UIColor.init(red: CGFloat(((color >> 16) & 0xFF)) / 255.0, green: CGFloat(((color >> 8) & 0xFF)) / 255.0, blue: CGFloat(((color >> 0) & 0xFF)) / 255.0, alpha: 255.0)
    }
    
    class func colorWithARGB(_ color: UInt64) -> UIColor {
        return UIColor.init(red: CGFloat(((color >> 16) & 0xFF)) / 255.0, green: CGFloat(((color >> 8) & 0xFF)) / 255.0, blue: CGFloat(((color >> 0) & 0xFF)) / 255.0, alpha: CGFloat(((color >> 24) & 0xFF)) / 255.0)
    }
    
    class func colorWithRGBA(_ color: UInt64) -> UIColor {
        return UIColor.init(red: CGFloat(((color >> 24) & 0xFF)) / 255.0, green: CGFloat(((color >> 16) & 0xFF)) / 255.0, blue: CGFloat(((color >> 8) & 0xFF)) / 255.0, alpha: CGFloat(((color) & 0xFF)) / 255.0)
    }
    
    class func colorWithRGBWithString(_ colorString: String) -> UIColor {
        let color: UnsafeMutablePointer<UInt64> = UnsafeMutablePointer.init(bitPattern: 0)!
        let scanner: Scanner = Scanner.init(string: colorString)
        
        //    [scanner setScanLocation:1]; // bypass '#' character
        scanner.scanHexInt64(color)
        return UIColor.colorWithRGB(color.pointee)
    }
}
