import Foundation
import Network
import SwiftUI
import AVFoundation

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
    var nearbyReadyPeerNames: [String] = []
    var questionQueue: [String] = []
    var currentDisplayedQuestion: String?
    var hostName: String = ""
    var isConnectingToHost: Bool = false
    var hostRound: Int = 0
    var peersWereNearbyAtHostStart: Bool = false
    var toast: ToastMessage?

    func showToast(_ message: String, duration: Double = 3.0, x: CGFloat = 0.5, y: CGFloat = 0.5) {
        let newToast = ToastMessage(text: message, duration: duration, x: x, y: y)
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
    @ObservationIgnored private var readyListener: NWListener?
    @ObservationIgnored private var browser: NWBrowser?
    @ObservationIgnored private var hostBrowser: NWBrowser?
    @ObservationIgnored private var hostConnection: NWConnection?
    @ObservationIgnored private var playerConnections: [NWConnection] = []
    @ObservationIgnored private var connectionNames: [ObjectIdentifier: String] = [:]
    @ObservationIgnored private var connectedEndpoints: Set<String> = []
    @ObservationIgnored private var connectedDeviceIDs: Set<String> = []
    @ObservationIgnored private var connectionDeviceIDs: [ObjectIdentifier: String] = [:]
    @ObservationIgnored private var reconnectAttempts: Int = 0
    @ObservationIgnored private var lastLeftHostName: String?
    @ObservationIgnored private var lastBrowseResults: Set<NWBrowser.Result> = []
    @ObservationIgnored private var wantsToJoin: Bool = false
    @ObservationIgnored private var keepAliveTimer: DispatchSourceTimer?
    @ObservationIgnored private var hostRetryTimer: DispatchSourceTimer?

    private let audioQueue = DispatchQueue(label: "com.bjanish.theseat.audio")
    private let serviceType = "_theseat._tcp"

    // MARK: - Audio

    @ObservationIgnored private var pingPlayer: AVAudioPlayer?

    private func loadPingSound() {
        Task.detached {
            guard let url = Bundle.main.url(forResource: "Funk", withExtension: "aiff") else { return }
            let player = try? AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            await MainActor.run { [weak self] in
                self?.pingPlayer = player
            }
        }
    }

    private func playPing() {
        guard let player = pingPlayer else { return }
        audioQueue.async {
            player.currentTime = 0
            player.play()
        }
    }

    private func primeAudio() {
        guard let player = pingPlayer else { return }
        audioQueue.async {
            let originalVolume = player.volume
            player.volume = 0
            player.currentTime = 0
            player.play()
            player.stop()
            player.volume = originalVolume
        }
    }

    // MARK: - Init

    init() {
        #if DEBUG
        print("[SESSION] SessionManager initialized, deviceID: \(deviceID)")
        #endif
        loadPingSound()
    }

    // MARK: - Host

    func startHosting() {
        peersWereNearbyAtHostStart = !nearbyReadyPeerNames.isEmpty
        role = .host
        UIApplication.shared.isIdleTimerDisabled = true
        stopBrowser()
        stopReadyListener()
        startHostListener()
        startHostBrowser()
        startKeepAlive()
        primeAudio()
        #if DEBUG
        print("[HOST] Started hosting session")
        #endif
    }

    // MARK: - Simulated Characters (DEBUG only)

    #if DEBUG
    @ObservationIgnored private var characterNames = ["Charlie", "Lucy", "Schroeder"]
    private let characterQuestions = [
        "What's the wildest thing you've done that nobody here knows about?",
        "Have you ever hooked up with someone in this room?",
        "What's the most inappropriate thought you've had at work?",
        "Who here would you most want to see naked?",
        "What's your body count?",
        "What's the worst lie you've told to get someone into bed?",
        "Have you ever faked it? Be honest.",
        "What's the kinkiest thing on your bucket list?",
        "Who's the last person you stalked on Instagram at 2am?",
        "What's the drunkest you've ever been and what happened?",
        "Have you ever sent a nude to the wrong person?",
        "What's something you'd never admit to your partner?",
        "What's the most embarrassing thing in your search history?",
        "Who in this room do you think is secretly a freak?",
        "What's the worst reason you've ghosted someone?",
        "What's your biggest red flag that you're aware of?",
        "Who's your most regrettable hookup?",
        "What's the most desperate thing you've done for attention?",
        "Have you ever lied about finishing?",
        "What's the horniest decision you've ever made?",
        "Who in this room would you trust with a secret the least?",
        "What's the worst thing you've done while drunk that you remember?",
        "Have you ever been the other person in someone's relationship?",
        "What's the most unhinged text you've sent at 3am?",
        "Who here do you think has the most secrets?",
        "What's something you've done that would ruin your reputation?",
        "Have you ever caught feelings for someone you shouldn't have?",
        "What's the biggest lie you're currently living?",
        "What would your ex say is the worst thing about you?",
        "Have you ever pretended to be drunker than you were? Why?"
    ]

    private func startSimulatedCharacters() {
        for (index, name) in characterNames.enumerated() {
            let delay = Double(index) * 1.5
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, self.role == .host else { return }
                self.connectedPeers.append(name)
                self.showToast("\(name) joined", y: 0.12)
            }
        }

        let shuffled = characterQuestions.shuffled()
        for (index, _) in characterNames.enumerated() {
            let joinDelay = Double(index) * 1.5
            let questionDelay = joinDelay + Double.random(in: 5.0...12.0)
            let question = shuffled[index]
            DispatchQueue.main.asyncAfter(deadline: .now() + questionDelay) { [weak self] in
                guard let self, self.role == .host else { return }
                let formatted = question.hasSuffix("?") ? question : question + "?"
                self.questionQueue.insert(formatted, at: 0)
                self.playPing()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                print("[CHARACTER] sent: \(question.prefix(30))...")
            }
        }
    }
    #endif

    func endSession() {
        let hadPlayers = !connectedPeers.isEmpty
        sendToAllPlayers(.sessionEnd)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.tearDown()
            self?.role = .solo
            if hadPlayers {
                self?.showToast("The Seat is empty", y: 0.04)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self?.startBrowser()
            }
            #if DEBUG
            print("[HOST] The Seat is empty")
            #endif
        }
    }

    func selectQuestion(at index: Int) {
        guard index < questionQueue.count else { return }
        let question = questionQueue[index]
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
        sendToAllPlayers(.newHost(name: name))
        role = .player
        hostName = name
        questionQueue.removeAll()
        currentDisplayedQuestion = nil
        #if DEBUG
        print("[HOST] Passed the seat to \(name)")
        #endif
    }

    // MARK: - Player

    func joinSession() {
        guard !wantsToJoin else { return }
        wantsToJoin = true
        // Bounce the ready listener to force fresh Bonjour advertisement
        // This ensures the host's browser sees a new result and retries connection
        stopReadyListener()
        startReadyListener()
        #if DEBUG
        print("[PLAYER] Wants to join — bounced ready listener, waiting for host to connect")
        #endif
    }

    func sendQuestion(_ text: String) {
        guard let connection = hostConnection else { return }
        send(.question(text: text), to: connection)
        #if DEBUG
        print("[PLAYER] Question sent: \(text.prefix(30))...")
        #endif
    }

    func leaveSession() {
        let leftHost = hostName
        lastLeftHostName = leftHost
        stopKeepAlive()
        UIApplication.shared.isIdleTimerDisabled = false
        stopReadyListener()
        hostConnection?.cancel()
        hostConnection = nil
        role = .solo
        hostName = ""
        currentDisplayedQuestion = nil
        reconnectAttempts = 0
        startBrowser()
        // Restart ready listener after delay so host can't immediately reconnect
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self, self.role == .solo else { return }
            self.startReadyListener()
        }
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
            stopKeepAlive()
            UIApplication.shared.isIdleTimerDisabled = false
            hostConnection?.cancel()
            hostConnection = nil
            role = .solo
            hostName = ""
            stopBrowser()
            stopReadyListener()
            lastLeftHostName = nil
        case .solo:
            stopBrowser()
            stopReadyListener()
        }
    }

    func resumeFromBackground() {
        lastLeftHostName = nil
        reconnectAttempts = 0
        if role == .solo, UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
            startBrowser()
        }
    }

    // MARK: - Private: Host Listener (advertises -host for discovery + accepts player connections)

    private func startHostListener() {
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

            listener.start(queue: .main)
            self.listener = listener
        } catch {
            #if DEBUG
            print("[HOST] Failed to start listener: \(error)")
            #endif
        }
    }

    // MARK: - Private: Host Browser (finds -ready players and connects TO them)

    private func startHostBrowser() {
        let params = NWParameters()
        params.includePeerToPeer = true
        let hb = NWBrowser(for: .bonjour(type: serviceType, domain: nil), using: params)

        hb.browseResultsChangedHandler = { [weak self] results, _ in
            Task { @MainActor in
                self?.handleHostBrowseResults(results)
            }
        }

        hb.stateUpdateHandler = { state in
            #if DEBUG
            print("[HOST-BROWSER] State: \(state)")
            #endif
        }

        hb.start(queue: .main)
        hostBrowser = hb

        // Retry connecting to discovered players every 3 seconds
        // (handles the case where player taps Join after host already attempted)
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 3.0, repeating: 3.0)
        timer.setEventHandler { [weak self] in
            guard let self, self.role == .host else { return }
            if let results = self.hostBrowser?.browseResults {
                self.handleHostBrowseResults(results)
            }
        }
        timer.resume()
        hostRetryTimer = timer

        #if DEBUG
        print("[HOST-BROWSER] Started browsing for players")
        #endif
    }

    private func stopHostBrowser() {
        hostBrowser?.cancel()
        hostBrowser = nil
        hostRetryTimer?.cancel()
        hostRetryTimer = nil
    }

    private func handleHostBrowseResults(_ results: Set<NWBrowser.Result>) {
        guard role == .host else { return }
        let selfPrefix = "\(playerName)-\(deviceID)"

        for result in results {
            guard case let .service(name, _, _, _) = result.endpoint else { continue }
            if name.hasPrefix(selfPrefix) { continue }

            let parts = name.components(separatedBy: "-")
            guard parts.count >= 3 else { continue }
            let serviceState = parts.last

            // Only connect to -ready services (players waiting to join)
            guard serviceState == "ready" else { continue }

            // Don't connect to players we already have
            let endpointDesc = "\(result.endpoint)"
            let endpointBase = endpointDesc.components(separatedBy: ":").dropLast().joined(separator: ":")
            guard !connectedEndpoints.contains(endpointBase) else { continue }

            // Connect TO this player
            #if DEBUG
            let peerName = parts.dropLast(2).joined(separator: "-")
            print("[HOST] Connecting to player: \(peerName) at \(result.endpoint)")
            #endif
            connectToPlayer(endpoint: result.endpoint)
        }
    }

    private func connectToPlayer(endpoint: NWEndpoint) {
        let params = NWParameters.tcp
        params.includePeerToPeer = true
        let connection = NWConnection(to: endpoint, using: params)

        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                switch state {
                case .ready:
                    #if DEBUG
                    print("[HOST] Connection to player ready")
                    #endif
                    self?.handleNewPlayerConnection(connection)
                case .failed, .cancelled:
                    #if DEBUG
                    print("[HOST] Connection to player failed/cancelled")
                    #endif
                default:
                    break
                }
            }
        }

        connection.start(queue: .main)
    }

    // MARK: - Private: Ready Listener (player advertises presence + accepts host connections)

    private func startReadyListener() {
        guard readyListener == nil, role == .solo else { return }
        do {
            let params = NWParameters.tcp
            params.includePeerToPeer = true
            let rl = try NWListener(using: params)
            let serviceName = "\(playerName)-\(deviceID)-ready"
            rl.service = NWListener.Service(name: serviceName, type: serviceType)

            rl.newConnectionHandler = { [weak self] connection in
                Task { @MainActor in
                    self?.handleIncomingHostConnection(connection)
                }
            }

            rl.stateUpdateHandler = { state in
                #if DEBUG
                print("[READY] Listener state: \(state)")
                #endif
            }

            rl.start(queue: .main)
            readyListener = rl
        } catch {
            #if DEBUG
            print("[READY] Failed to advertise presence: \(error)")
            #endif
        }
    }

    private func stopReadyListener() {
        readyListener?.cancel()
        readyListener = nil
        nearbyReadyPeerNames = []
    }

    /// Player receives an incoming connection from the host
    private func handleIncomingHostConnection(_ connection: NWConnection) {
        // Only accept if we're solo AND the player has tapped Join
        guard role == .solo, wantsToJoin else {
            connection.cancel()
            return
        }
        wantsToJoin = false

        #if DEBUG
        print("[PLAYER] Incoming connection from host")
        #endif

        isConnectingToHost = true
        hostConnection = connection
        role = .player
        UIApplication.shared.isIdleTimerDisabled = true
        stopBrowser()

        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                self?.handlePlayerConnectionState(state, connection: connection)
            }
        }

        connection.start(queue: .main)

        // Send join and start receive after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            self.isConnectingToHost = false
            self.send(.join(name: self.playerName, deviceID: self.deviceID), to: connection)
            self.receiveLoop(from: connection)
            self.startKeepAlive()
        }
    }

    // MARK: - Private: Handle New Player Connection (host side)

    private func handleNewPlayerConnection(_ connection: NWConnection) {
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

        // If connection isn't ready yet (came from listener), set up state handler
        if connection.state != .ready {
            connection.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    switch state {
                    case .ready:
                        #if DEBUG
                        print("[HOST] Player connection ready")
                        #endif
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self?.receiveLoop(from: connection)
                        }
                        // Ghost timeout
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                            guard let self else { return }
                            let id = ObjectIdentifier(connection)
                            if self.connectionNames[id] == nil {
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
            connection.start(queue: .main)
            playerConnections.append(connection)
        } else {
            // Already ready (came from host-initiated connectToPlayer)
            #if DEBUG
            print("[HOST] Player connection ready")
            #endif
            playerConnections.append(connection)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.receiveLoop(from: connection)
            }
            // Ghost timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                guard let self else { return }
                let id = ObjectIdentifier(connection)
                if self.connectionNames[id] == nil {
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
        }
    }

    private func handleHostDisconnect(_ connection: NWConnection) {
        let id = ObjectIdentifier(connection)
        let hadName = connectionNames[id] != nil
        if let name = connectionNames[id] {
            connectedPeers.removeAll { $0 == name }
            showToast("\(name) left", y: 0.12)
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

        // If all real players left, end the session automatically
        if hadName && connectedPeers.isEmpty && role == .host {
            endSession()
        }
    }

    // MARK: - Private: Solo Browser (finds hosts + ready peers for UI)

    func startBrowser() {
        guard role == .solo else { return }

        startReadyListener()

        guard browser == nil else { return }

        let params = NWParameters()
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

        browser.start(queue: .main)
        self.browser = browser

        #if DEBUG
        print("[BROWSER] Started browsing")
        #endif
    }

    private func stopBrowser() {
        browser?.cancel()
        browser = nil
        nearbyReadyPeerNames = []
    }

    private func handleBrowseResults(_ results: Set<NWBrowser.Result>) {
        lastBrowseResults = results
        let selfPrefix = "\(playerName)-\(deviceID)"
        var readyPeerNames: [String] = []
        var discoveredHost: (name: String, endpoint: NWEndpoint)?
        var visibleHostServiceNames: Set<String> = []

        for result in results {
            guard case let .service(name, _, _, _) = result.endpoint else { continue }
            if name.hasPrefix(selfPrefix) { continue }

            let parts = name.components(separatedBy: "-")
            guard parts.count >= 3 else { continue }

            let peerName = parts.dropLast(2).joined(separator: "-")
            let serviceState = parts.last

            switch serviceState {
            case "ready":
                if !peerName.isEmpty {
                    readyPeerNames.append(peerName)
                }
            case "host":
                visibleHostServiceNames.insert(name)
                if let leftHost = lastLeftHostName, name.contains(leftHost) { continue }
                guard reconnectAttempts < 3, discoveredHost == nil else { continue }
                discoveredHost = (peerName, result.endpoint)
            default:
                continue
            }
        }

        nearbyReadyPeerNames = readyPeerNames.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

        #if DEBUG
        let hostServices = visibleHostServiceNames.isEmpty ? "none" : visibleHostServiceNames.joined(separator: ", ")
        print("[BROWSE] Ready peers: \(nearbyReadyPeerNames), Hosts: \(hostServices)")
        #endif

        if let leftHost = lastLeftHostName,
           !visibleHostServiceNames.contains(where: { $0.contains(leftHost) }) {
            lastLeftHostName = nil
        }

        guard role == .solo else { return }

        if let discoveredHost {
            if hostName != discoveredHost.name {
                #if DEBUG
                print("[BROWSE] hostName changed: \(hostName) → \(discoveredHost.name)")
                #endif
            }
            hostName = discoveredHost.name
        } else {
            if !hostName.isEmpty {
                #if DEBUG
                print("[BROWSE] hostName cleared (no hosts visible)")
                #endif
            }
            hostName = ""
        }
    }

    // MARK: - Private: Player Connection State

    private func handlePlayerConnectionState(_ state: NWConnection.State, connection: NWConnection) {
        switch state {
        case .ready:
            // Connection already handled in handleIncomingHostConnection
            break
        case .failed, .cancelled:
            guard hostConnection === connection else { return }
            isConnectingToHost = false
            hostConnection = nil
            stopKeepAlive()
            if role == .player {
                role = .solo
                UIApplication.shared.isIdleTimerDisabled = false
                hostName = ""
                currentDisplayedQuestion = nil
                showToast("The Seat is empty", y: 0.04)
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

    // MARK: - Keep-Alive (prevents AWDL from going idle)

    private func startKeepAlive() {
        guard keepAliveTimer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 2.0, repeating: 2.0)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            switch self.role {
            case .host:
                self.sendToAllPlayers(.heartbeat)
            case .player:
                if let connection = self.hostConnection {
                    self.send(.heartbeat, to: connection)
                }
            case .solo:
                break
            }
        }
        timer.resume()
        keepAliveTimer = timer
    }

    private func stopKeepAlive() {
        keepAliveTimer?.cancel()
        keepAliveTimer = nil
    }

    private func receiveLoop(from connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 4, maximumLength: 4) { [weak self] data, _, _, error in
            Task { @MainActor in
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
            Task { @MainActor in
                guard let self else { return }
                guard let data else {
                    self.handleDisconnect(connection)
                    return
                }
                if let message = try? JSONDecoder().decode(SeatMessage.self, from: data) {
                    self.handleMessage(message, from: connection)
                }
                self.receiveLoop(from: connection)
            }
        }
    }

    private func handleDisconnect(_ connection: NWConnection) {
        if connection === hostConnection {
            hostConnection = nil
            stopKeepAlive()
            if role == .player {
                role = .solo
                UIApplication.shared.isIdleTimerDisabled = false
                hostName = ""
                currentDisplayedQuestion = nil
                showToast("The Seat is empty", y: 0.04)
                reconnectAttempts = 0
                lastLeftHostName = nil
                startBrowser()
            }
        } else {
            handleHostDisconnect(connection)
        }
    }

    private func handleMessage(_ message: SeatMessage, from connection: NWConnection) {
        switch message {
        case .join(let name, let incomingDeviceID):
            guard !connectedDeviceIDs.contains(incomingDeviceID) else {
                connection.cancel()
                return
            }

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
            showToast("\(finalName) joined", y: 0.12)
            send(.welcome(hostName: playerName), to: connection)

            #if DEBUG
            print("[HOST] Player joined: \(finalName) (device: \(incomingDeviceID))")
            #endif

        case .welcome(let name):
            hostName = name
            stopReadyListener()
            showToast("\(name) is in The Seat", y: 0.3)
            #if DEBUG
            print("[PLAYER] Host name updated via welcome: \(name)")
            #endif

        case .question(let text):
            let formatted = text.hasSuffix("?") ? text : text + "?"
            questionQueue.insert(formatted, at: 0)
            playPing()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
            peersWereNearbyAtHostStart = true
            questionQueue.removeAll()
            currentDisplayedQuestion = nil

        case .newHost(let name):
            hostName = name
            hostRound += 1
            currentDisplayedQuestion = nil
            showToast("\(name) is in The Seat", y: 0.3)
            #if DEBUG
            print("[PLAYER] New host: \(name)")
            #endif

        case .sessionEnd:
            hostConnection?.cancel()
            hostConnection = nil
            role = .solo
            UIApplication.shared.isIdleTimerDisabled = false
            hostName = ""
            currentDisplayedQuestion = nil
            showToast("The Seat is empty", y: 0.04)
            startBrowser()
            #if DEBUG
            print("[PLAYER] The Seat is empty")
            #endif

        case .heartbeat:
            break
        }
    }

    // MARK: - Private: Teardown

    private func tearDown() {
        stopKeepAlive()
        UIApplication.shared.isIdleTimerDisabled = false
        listener?.cancel()
        listener = nil
        stopReadyListener()
        stopHostBrowser()
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
        peersWereNearbyAtHostStart = false
        lastBrowseResults = []
    }
}
