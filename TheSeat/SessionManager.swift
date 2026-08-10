import Foundation
import Network
import SwiftUI

@MainActor @Observable
final class SessionManager {

    // MARK: - Session State

    enum Role {
        case solo
        case host
        case player
    }

    var role: Role = .solo
    var playerName: String = UserDefaults.standard.string(forKey: "playerName") ?? ""
    var connectedPeers: [String] = []
    var questionQueue: [String] = []
    var currentDisplayedQuestion: String?
    var hostName: String = ""
    var isConnectingToHost: Bool = false
    var hostRound: Int = 0
    var toast: ToastMessage?

    func showToast(_ message: String, duration: Double = 3.0) {
        let newToast = ToastMessage(text: message, duration: duration)
        toast = newToast
        let toastId = newToast.id
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            if self?.toast?.id == toastId {
                self?.toast = nil
            }
        }
    }

    // MARK: - Device ID

    var deviceID: String {
        if let existing = UserDefaults.standard.string(forKey: "deviceID") {
            return existing
        }
        let newID = String(UUID().uuidString.prefix(6))
        UserDefaults.standard.set(newID, forKey: "deviceID")
        return newID
    }

    // MARK: - Networking

    @ObservationIgnored private var listener: NWListener?
    @ObservationIgnored private var browser: NWBrowser?
    @ObservationIgnored private var hostConnection: NWConnection?
    @ObservationIgnored private var playerConnections: [NWConnection] = []
    @ObservationIgnored private var connectionNames: [ObjectIdentifier: String] = [:]
    @ObservationIgnored private var connectedEndpoints: Set<String> = []
    @ObservationIgnored private var connectedDeviceIDs: Set<String> = []
    @ObservationIgnored private var connectionDeviceIDs: [ObjectIdentifier: String] = [:]
    @ObservationIgnored private var reconnectAttempts: Int = 0
    @ObservationIgnored private var lastLeftHostName: String?

    private let networkQueue = DispatchQueue(label: "com.bjanish.theseat.network")

    private let serviceType = "_theseat._tcp"

    // MARK: - Init

    init() {
        #if DEBUG
        print("[SESSION] SessionManager initialized, deviceID: \(deviceID)")
        #endif
        // Start browsing immediately so we see hosts on the solo screen
        startBrowser()
    }

    // MARK: - Host

    func startHosting() {
        role = .host
        stopBrowser()
        startListener()
        #if DEBUG
        print("[HOST] Started hosting session")
        #endif
    }

    func endSession() {
        sendToAllPlayers(.sessionEnd)
        // Tear down after a brief moment to let the message send
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.tearDown()
            self?.role = .solo
            self?.announcedHosts = []
            self?.showToast("Session ended")
            // Restart browser after delay so other phones can see future hosts
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self?.startBrowser()
            }
            #if DEBUG
            print("[HOST] Session ended")
            #endif
        }
    }

    func selectQuestion(at index: Int) {
        guard index < questionQueue.count else { return }
        let question = questionQueue.remove(at: index)
        currentDisplayedQuestion = question
        sendToAllPlayers(.currentQuestion(text: question))
    }

    func skipQuestion(at index: Int) {
        guard index < questionQueue.count else { return }
        questionQueue.remove(at: index)
    }

    func passTheSeat(to name: String) {
        guard let id = connectionNames.first(where: { $0.value == name })?.key,
              let connection = playerConnections.first(where: { ObjectIdentifier($0) == id }) else { return }
        send(.passTheSeat(toName: name), to: connection)
        send(.youAreHost, to: connection)

        // Broadcast new host to all players
        sendToAllPlayers(.newHost(name: name))

        // Transition self to player
        role = .player
        hostName = name
        questionQueue.removeAll()
        currentDisplayedQuestion = nil

        #if DEBUG
        print("[HOST] Passed the seat to \(name)")
        #endif
    }

    // MARK: - Player

    @ObservationIgnored private var wantsToJoin: Bool = false
    @ObservationIgnored private var lastBrowseResults: Set<NWBrowser.Result> = []
    @ObservationIgnored private var announcedHosts: Set<String> = []

    func joinSession() {
        wantsToJoin = true
        // If we already have browse results, process them now
        if !lastBrowseResults.isEmpty {
            handleBrowseResults(lastBrowseResults)
        }
    }

    func connectToHost(endpoint: NWEndpoint) {
        guard !isConnectingToHost else { return }
        isConnectingToHost = true

        #if DEBUG
        print("[CONNECT] Connecting to: \(endpoint)")
        #endif

        let params = NWParameters.tcp
        params.includePeerToPeer = true
        let connection = NWConnection(to: endpoint, using: params)
        hostConnection = connection

        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                self?.handlePlayerConnectionState(state, connection: connection)
            }
        }

        connection.start(queue: networkQueue)

        // 3-second timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self, self.isConnectingToHost, connection.state != .ready else { return }
            connection.cancel()
            self.isConnectingToHost = false
            self.reconnectAttempts += 1
            #if DEBUG
            print("[CONNECT] Connection timeout")
            #endif
        }
    }

    func sendQuestion(_ text: String) {
        guard let connection = hostConnection else { return }
        send(.question(text: text), to: connection)
    }

    func leaveSession() {
        let leftHost = hostName
        lastLeftHostName = leftHost
        hostConnection?.cancel()
        hostConnection = nil
        role = .solo
        hostName = ""
        reconnectAttempts = 0
        startBrowser()
        // Clear lastLeftHostName after 3 seconds so player can rejoin
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            if self?.lastLeftHostName == leftHost {
                self?.lastLeftHostName = nil
            }
        }
        #if DEBUG
        print("[PLAYER] Left session intentionally")
        #endif
    }

    // MARK: - Lifecycle

    func enterBackground() {
        switch role {
        case .host:
            endSession()
        case .player:
            hostConnection?.cancel()
            hostConnection = nil
            role = .solo
            hostName = ""
            stopBrowser()
            lastLeftHostName = nil
        case .solo:
            stopBrowser()
        }
    }

    func resumeFromBackground() {
        lastLeftHostName = nil
        reconnectAttempts = 0
        if role == .solo {
            startBrowser()
        }
    }

    // MARK: - Private: Listener

    private func startListener() {
        do {
            let params = NWParameters.tcp
            params.includePeerToPeer = true
            let listener = try NWListener(using: params)
            let serviceName = "\(playerName)-\(deviceID)-host"
            listener.service = NWListener.Service(name: serviceName, type: serviceType)

            listener.newConnectionHandler = { [weak self] connection in
                Task { @MainActor in
                    self?.handleNewPlayerConnection(connection)
                }
            }

            listener.stateUpdateHandler = { state in
                #if DEBUG
                print("[HOST] Listener state: \(state)")
                #endif
            }

            listener.start(queue: networkQueue)
            self.listener = listener
        } catch {
            #if DEBUG
            print("[HOST] Failed to start listener: \(error)")
            #endif
        }
    }

    private func handleNewPlayerConnection(_ connection: NWConnection) {
        // Endpoint dedup — strip port to catch same device on different ports
        let endpointDesc = "\(connection.endpoint)"
        let endpointBase = endpointDesc.components(separatedBy: ":").dropLast().joined(separator: ":")
        #if DEBUG
        print("[HOST] New connection from: \(endpointDesc) (base: \(endpointBase))")
        print("[HOST] Current endpoints: \(connectedEndpoints)")
        #endif
        guard !connectedEndpoints.contains(endpointBase) else {
            #if DEBUG
            print("[HOST] Duplicate endpoint rejected: \(endpointBase)")
            #endif
            connection.cancel()
            return
        }
        connectedEndpoints.insert(endpointBase)

        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                switch state {
                case .ready:
                    #if DEBUG
                    print("[HOST] Player connection ready")
                    #endif
                    // Start receive loop after brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self?.receiveLoop(from: connection)
                    }
                    // Timeout — if no .join received in 3 seconds, cancel
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                        guard let self else { return }
                        let id = ObjectIdentifier(connection)
                        if self.connectionNames[id] == nil {
                            // Never got a .join — ghost connection
                            connection.cancel()
                            self.playerConnections.removeAll { $0 === connection }
                            let endpointDesc = "\(connection.endpoint)"
                            let endpointBase = endpointDesc.components(separatedBy: ":").dropLast().joined(separator: ":")
                            self.connectedEndpoints.remove(endpointBase)
                            #if DEBUG
                            print("[HOST] Ghost connection timed out — no .join received")
                            #endif
                        }
                    }
                case .failed, .cancelled:
                    self?.handleHostDisconnect(connection)
                default:
                    break
                }
            }
        }

        connection.start(queue: networkQueue)
        playerConnections.append(connection)
    }

    private func handleHostDisconnect(_ connection: NWConnection) {
        let id = ObjectIdentifier(connection)
        if let name = connectionNames[id] {
            connectedPeers.removeAll { $0 == name }
            showToast("\(name) left")
            #if DEBUG
            print("[DISCONNECT] Player disconnected: \(name)")
            #endif
        }
        if let did = connectionDeviceIDs[id] {
            connectedDeviceIDs.remove(did)
        }
        let endpointDesc = "\(connection.endpoint)"
        let endpointBase = endpointDesc.components(separatedBy: ":").dropLast().joined(separator: ":")
        connectedEndpoints.remove(endpointBase)
        connectionNames.removeValue(forKey: id)
        connectionDeviceIDs.removeValue(forKey: id)
        playerConnections.removeAll { $0 === connection }

        // End session if last player left
        if connectedPeers.isEmpty && role == .host {
            // Don't auto-end — host still needs to see/answer questions
            // Host ends manually with "End" button
        }
    }

    // MARK: - Private: Browser

    func startBrowser() {
        // Don't start if already browsing
        guard browser == nil else { return }

        let params = NWParameters.tcp
        params.includePeerToPeer = true
        let browser = NWBrowser(for: .bonjour(type: serviceType, domain: nil), using: params)

        browser.browseResultsChangedHandler = { [weak self] results, _ in
            Task { @MainActor in
                self?.handleBrowseResults(results)
            }
        }

        browser.stateUpdateHandler = { [weak self] state in
            #if DEBUG
            print("[BROWSER] State: \(state)")
            #endif
            if case .failed = state {
                Task { @MainActor in
                    self?.stopBrowser()
                }
            }
        }

        browser.start(queue: networkQueue)
        self.browser = browser

        #if DEBUG
        print("[BROWSER] Started browsing")
        #endif
    }

    private func stopBrowser() {
        browser?.cancel()
        browser = nil
    }

    private func handleBrowseResults(_ results: Set<NWBrowser.Result>) {
        lastBrowseResults = results
        let selfPrefix = "\(playerName)-\(deviceID)"

        for result in results {
            guard case let .service(name, _, _, _) = result.endpoint else { continue }

            // Self-filter
            if name.hasPrefix(selfPrefix) { continue }

            // Only connect to hosts
            guard name.hasSuffix("-host") else { continue }

            // Skip intentionally left host
            if let leftHost = lastLeftHostName, name.contains(leftHost) { continue }

            // Circuit breaker
            guard reconnectAttempts < 3 else { continue }

            // Extract host name
            let parts = name.components(separatedBy: "-")
            let discoveredHostName = parts.count >= 3 ? parts.dropLast(2).joined(separator: "-") : name

            if role == .solo {
                if wantsToJoin && !isConnectingToHost {
                    // Player tapped "Join" — connect
                    hostName = discoveredHostName
                    wantsToJoin = false
                    connectToHost(endpoint: result.endpoint)
                    break
                } else if !wantsToJoin && !isConnectingToHost {
                    // Just browsing — update hostName so button text changes
                    if !announcedHosts.contains(name) {
                        announcedHosts.insert(name)
                        hostName = discoveredHostName
                    }
                    break
                }
            }
        }

        // If the host we left is no longer visible, clear lastLeftHostName
        if let leftHost = lastLeftHostName {
            let stillVisible = results.contains { result in
                if case let .service(name, _, _, _) = result.endpoint {
                    return name.contains(leftHost)
                }
                return false
            }
            if !stillVisible {
                lastLeftHostName = nil
            }
        }

        // Clear announced hosts that are no longer visible
        let currentServiceNames = Set(results.compactMap { result -> String? in
            if case let .service(name, _, _, _) = result.endpoint { return name }
            return nil
        })
        announcedHosts = announcedHosts.intersection(currentServiceNames)

        // If no hosts visible anymore, clear hostName
        let hasVisibleHost = results.contains { result in
            if case let .service(name, _, _, _) = result.endpoint {
                return name.hasSuffix("-host") && !name.hasPrefix("\(playerName)-\(deviceID)")
            }
            return false
        }
        if !hasVisibleHost && role == .solo {
            hostName = ""
        }
    }

    // MARK: - Private: Player Connection State

    private func handlePlayerConnectionState(_ state: NWConnection.State, connection: NWConnection) {
        switch state {
        case .ready:
            isConnectingToHost = false
            reconnectAttempts = 0
            role = .player
            stopBrowser()
            showToast(hostName.isEmpty ? "Connected" : "\(hostName) is hosting")
            #if DEBUG
            print("[CONNECT] Connected to host")
            #endif
            // Send join and start receive after brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self else { return }
                self.send(.join(name: self.playerName, deviceID: self.deviceID), to: connection)
                self.receiveLoop(from: connection)
            }
        case .failed, .cancelled:
            guard hostConnection === connection else { return }
            isConnectingToHost = false
            hostConnection = nil
            if role == .player {
                role = .solo
                hostName = ""
                currentDisplayedQuestion = nil
                showToast("Session ended")
                reconnectAttempts += 1
                startBrowser()
            }
            #if DEBUG
            print("[CONNECT] Connection failed/cancelled")
            #endif
        default:
            break
        }
    }

    // MARK: - Private: Send/Receive

    private func send(_ message: SeatMessage, to connection: NWConnection) {
        guard let data = try? JSONEncoder().encode(message) else { return }
        var length = UInt32(data.count).bigEndian
        var frame = Data(bytes: &length, count: 4)
        frame.append(data)
        connection.send(content: frame, completion: .contentProcessed({ _ in }))
    }

    private func sendToAllPlayers(_ message: SeatMessage) {
        for connection in playerConnections {
            send(message, to: connection)
        }
    }

    private func receiveLoop(from connection: NWConnection) {
        // Read 4-byte length prefix
        connection.receive(minimumIncompleteLength: 4, maximumLength: 4) { [weak self] data, _, _, error in
            DispatchQueue.main.async {
                guard let self else { return }
                guard let data, data.count == 4 else {
                    self.handleDisconnect(connection)
                    return
                }
                let length = data.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
                self.receiveBody(from: connection, length: Int(length))
            }
        }
    }

    private func receiveBody(from connection: NWConnection, length: Int) {
        connection.receive(minimumIncompleteLength: length, maximumLength: length) { [weak self] data, _, _, error in
            DispatchQueue.main.async {
                guard let self else { return }
                guard let data else {
                    self.handleDisconnect(connection)
                    return
                }
                if let message = try? JSONDecoder().decode(SeatMessage.self, from: data) {
                    self.handleMessage(message, from: connection)
                }
                // Continue receiving
                self.receiveLoop(from: connection)
            }
        }
    }

    private func handleDisconnect(_ connection: NWConnection) {
        if connection === hostConnection {
            // Player side — host dropped
            hostConnection = nil
            if role == .player {
                role = .solo
                hostName = ""
                currentDisplayedQuestion = nil
                showToast("Session ended")
                reconnectAttempts = 0
                lastLeftHostName = nil
                startBrowser()
            }
        } else {
            // Host side — player dropped
            handleHostDisconnect(connection)
        }
    }

    private func handleMessage(_ message: SeatMessage, from connection: NWConnection) {
        switch message {
        case .join(let name, let incomingDeviceID):
            // Dedup by device ID
            guard !connectedDeviceIDs.contains(incomingDeviceID) else {
                connection.cancel()
                return
            }

            // Same-name handling
            var finalName = name
            if connectedPeers.contains(name) {
                var suffix = 2
                while connectedPeers.contains("\(name) \(suffix)") { suffix += 1 }
                finalName = "\(name) \(suffix)"
            }

            let id = ObjectIdentifier(connection)
            connectedDeviceIDs.insert(incomingDeviceID)
            connectionDeviceIDs[id] = incomingDeviceID
            connectionNames[id] = finalName
            connectedPeers.append(finalName)
            showToast("\(finalName) joined")

            #if DEBUG
            print("[HOST] Player joined: \(finalName) (device: \(incomingDeviceID))")
            #endif

        case .question(let text):
            questionQueue.append(text)
            #if DEBUG
            print("[RECV] Question received: \(text.prefix(30))...")
            #endif

        case .currentQuestion(let text):
            currentDisplayedQuestion = text

        case .passTheSeat(let toName):
            if toName == playerName {
                role = .host
                questionQueue.removeAll()
                currentDisplayedQuestion = nil
                #if DEBUG
                print("[PLAYER] Received the seat — now hosting")
                #endif
            }

        case .youAreHost:
            role = .host
            questionQueue.removeAll()
            currentDisplayedQuestion = nil

        case .newHost(let name):
            hostName = name
            hostRound += 1
            currentDisplayedQuestion = nil
            showToast("\(name) is in the seat")
            #if DEBUG
            print("[PLAYER] New host: \(name)")
            #endif

        case .sessionEnd:
            hostConnection?.cancel()
            hostConnection = nil
            role = .solo
            hostName = ""
            currentDisplayedQuestion = nil
            showToast("Session ended")
            startBrowser()
            #if DEBUG
            print("[PLAYER] Session ended by host")
            #endif

        case .heartbeat:
            break
        }
    }

    // MARK: - Private: Teardown

    private func tearDown() {
        listener?.cancel()
        listener = nil
        browser?.cancel()
        browser = nil
        hostConnection?.cancel()
        hostConnection = nil

        for connection in playerConnections {
            connection.cancel()
        }
        playerConnections.removeAll()
        connectionNames.removeAll()
        connectedEndpoints.removeAll()
        connectedDeviceIDs.removeAll()
        connectionDeviceIDs.removeAll()
        connectedPeers.removeAll()
        questionQueue.removeAll()
        currentDisplayedQuestion = nil
        hostName = ""
        reconnectAttempts = 0
        wantsToJoin = false
        lastBrowseResults = []
        announcedHosts = []
    }
}
