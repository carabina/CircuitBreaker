import Foundation
import EmitterKit

public enum State {
    case OPEN
    case HALFOPEN
    case CLOSED
}

class CircuitBreaker {
    
    var state: State
    var failures: Int
    var resetTimer = Timer()
    var event: Event<Void>!
    var breaker: Stats!
    
    var timeout: Double
    var resetTimeout: Double
    var maxFailures: Double
    var pendingHalfOpen: Bool
    
    convenience init () {
        let opts: [String: Double] = [
            "timeout": 10.0, // 10 sec
            "resetTimeout": 60.0, // 1 min
            "maxFailures": 5.0
        ]
        self.init(opts: opts)
    }
    
    init (opts: [String: Double]) {
        self.timeout = opts["timeout"] ?? 10.0
        self.resetTimeout = opts["resetTimeout"] ?? 60.0
        self.maxFailures = opts["maxFailures"] ?? 5.0

        self.state = State.CLOSED
        self.failures = 0
        self.pendingHalfOpen = false
        self.event = Event<Void>()
        self.breaker = Stats(event: event)
    }
    
    /*
    // Invoke
    public func invoke () -> () {
        event.emit(breaker.trackRequest())
        
        if self.state == State.OPEN || (self.state == State.HALFOPEN && self.pendingHalfOpen == true) {
            return self.fastFail()
        } else if self.state == State.HALFOPEN && self.pendingHalfOpen != true {
            self.pendingHalfOpen = false
            return self.callFunction()
        } else {
            return self.callFunction()
        }
    }
    
    // fastFail
    public func fastFail () {
        
    }
    
    // callFunction
    public func callFunction () {
     
    }
    
    // handleTimeout
    public func handleTimeout () {
     
    }
    
    // callbackHandler
    public func callbackHandler () {
     
    }
    */
    
    public func getState () -> State {
        return self.state
    }
    
    public func setNumFailures (count: Int) {
        self.failures = count
    }
    
    public func getNumFailures () -> Int {
        return self.failures
    }
    
    public func handleFailures () {
        self.failures += 1
        
        if ((Double(self.failures) == self.maxFailures) || (self.getState() == State.HALFOPEN)) {
            self.forceOpen()
        }
        
        self.event.emit(self.breaker.trackFailedResponse())
    }
    
    public func handleSuccess () {
        self.forceClosed()
        
        self.event.emit(self.breaker.trackSuccessfulResponse())
    }
    
    public func forceOpen () {
        self.state = State.OPEN
        
        // TODO: Figure out timeout for sure
        //self.setTimeout(delay: self.resetTimeout)
    }
    
    public func forceClosed () {
        self.state = State.CLOSED
        self.failures = 0
    }
    
    public func forceHalfOpen () {
        self.state = State.HALFOPEN
    }
    
    @objc func updateState () {
        self.state = State.HALFOPEN
    }
    
    func setTimeout(delay:TimeInterval) {
        let timer = Timer(timeInterval: delay, target: self, selector: #selector(updateState), userInfo: nil, repeats: false)
        RunLoop.current.add(timer, forMode: RunLoopMode.commonModes)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: delay))
    }
    
    /*func setTimeout(delay:TimeInterval, block: @escaping ()->Void) -> Timer {
        print("In setTimeout")
        return Timer.scheduledTimer(timeInterval: delay, target: BlockOperation(block: block), selector: #selector(Operation.main), userInfo: nil, repeats: false)
    }
    
    func setInterval(interval:TimeInterval, block:@escaping ()->Void) -> Timer {
        return Timer.scheduledTimer(timeInterval: interval, target: BlockOperation(block: block), selector: #selector(Operation.main), userInfo: nil, repeats: true)
    }*/
    
}

