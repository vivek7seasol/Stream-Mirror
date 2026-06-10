//
//  SecodConfiguration.swift
//  
//
//

import Foundation

extension CommandNetwork {
    struct SecondConfigurationRequest: RequestDataProtocol {
        let data = Data([0x12, 0x3, 0x8, 0xEE, 0x4])
    }
}
