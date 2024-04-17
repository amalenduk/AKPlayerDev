//
//  AKNetworkReachabilityObserver.swift
//  AKPlayer
//
//  Copyright (c) 2020 Amalendu Kar
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import Network
import Combine

public protocol AKNetworkStatusMonitorProtocol {
    var networkPathMonitor: NWPathMonitor { get }
    var currentPath: NWPath { get }
    var currentNetworkStatus: NWPath.Status { get }
    var isConnected: Bool { get }
    var networkStatusPublisher: AnyPublisher<NWPath.Status, Never> { get }
    
    func startObserving()
    func stopObserving()
}

open class AKNetworkStatusMonitor: AKNetworkStatusMonitorProtocol {
    
    // MARK: - Properties
    
    public let networkPathMonitor: NWPathMonitor
    
    private var isObserving = false
    
    public var currentPath: NWPath {
        return networkPathMonitor.currentPath
    }
    
    public var currentNetworkStatus: NWPath.Status {
        return currentPath.status
    }
    
    public var isConnected: Bool {
        return currentNetworkStatus == .satisfied
    }
    
    private var networkStatusSubject: PassthroughSubject<NWPath.Status, Never> = PassthroughSubject<NWPath.Status, Never>()
    
    public var networkStatusPublisher: AnyPublisher<NWPath.Status, Never> {
        return networkStatusSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Init
    
    public init() {
        self.networkPathMonitor = NWPathMonitor()
        
        networkPathMonitor.pathUpdateHandler = { [unowned self] path in
            networkStatusSubject.send(path.status)
        }
    }
    
    deinit {
        stopObserving()
    }
    
    open func startObserving() {
        guard !isObserving else { return }
        
        networkPathMonitor.start(queue: DispatchQueue.global(qos: .background))
        
        isObserving = true
    }
    
    open func stopObserving() {
        guard isObserving else { return }
        
        networkPathMonitor.cancel()
        
        isObserving = false
    }
}

