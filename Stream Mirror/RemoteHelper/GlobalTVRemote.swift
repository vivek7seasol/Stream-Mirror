//
//  GlobalRemote.swift
//  TVRemote
//
//  Created by Parthiv Akbari on 17/02/26.
//

import Foundation

var remoteViewModel: TVRemoteViewModel {
    return TVRemoteSession.shared.viewModel
}
