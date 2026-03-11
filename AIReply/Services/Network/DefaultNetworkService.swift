//
//  DefaultNetworkService.swift
//  AIReply
//

import Foundation

/// Concrete network sender for dependency injection. Conforms to NetworkManagerService
/// so services can perform HTTP requests without depending on a ViewModel.
struct DefaultNetworkService: NetworkManagerService {}
