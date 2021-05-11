//
//  UIImage+Bundle.swift
//  IRMusicPlayer-swift
//
//  Created by Phil on 2021/2/18.
//  Copyright © 2021 Phil. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    class func imageNamedForCurrentBundle(named: String) -> UIImage? {
        return UIImage.init(named: named, in: Utilities.getCurrentBundle(), compatibleWith: nil)
    }
}
