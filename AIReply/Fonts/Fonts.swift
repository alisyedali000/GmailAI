//
//  File.swift
//  AIReply
//
//  Created by Syed Ahmad  on 01/03/2026.
//


import Foundation
import SwiftUI

extension Font {
    
    
    //MARK: Poppins
    static func bold(size: CGFloat) -> Font {
        self.custom("PlusJakartaSans-Bold", size: size)
    }
    
    static func semiBold(size: CGFloat) -> Font {
        self.custom("PlusJakartaSans-SemiBold", size: size)
    }
    
    static func medium(size: CGFloat) -> Font {
        self.custom("PlusJakartaSans-Medium", size: size)
    }
    
    static func regular(size: CGFloat) -> Font {
        self.custom("PlusJakartaSans-Regular", size: size)
    }
    
    static func extraBold(size: CGFloat) -> Font {
        self.custom("PlusJakartaSans-ExtraBold", size: size)
    }
    
    
}
