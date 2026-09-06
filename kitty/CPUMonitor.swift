import AppKit
import Combine
import Darwin.Mach

/// Samples aggregate CPU ticks locally. No processes, files, or personal data are inspected.
@MainActor
final class CPUMonitor: ObservableObject {
    enum Gait { case walking, running }

    @Published private(set) var usagePercent: Double = 0
    @Published private(set) var gait: Gait = .walking
    @Published private(set) var isSystemAsleep = false
    @Published private(set) var isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
    /// Runtime-only settings deliberately are not persisted to disk.
    @Published var threshold: Double = 70
    @Published var isAnimationPaused = false

    var shouldAnimate: Bool {
        !isAnimationPaused && !isSystemAsleep && !isLowPowerModeEnabled
    }

    private var timer: Timer?
    private var previousTicks: CPUTicks?
    private var highUsageStartedAt: Date?
    private var lowUsageStartedAt: Date?
    private var sleepObservers: [NSObjectProtocol] = []

    init() {
        observeSleepWake()
        sampleCPU()
        scheduleSamplingTimer()
    }

    deinit {
        timer?.invalidate()
        sleepObservers.forEach(NotificationCenter.default.removeObserver)
    }

    private func observeSleepWake() {
        let center = NSWorkspace.shared.notificationCenter
        sleepObservers = [
            center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.setSleepState(true) }
            },
            center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.setSleepState(false) }
            }
        ]
    }

    private func setSleepState(_ asleep: Bool) {
        isSystemAsleep = asleep
        // Do not interpret the elapsed sleep interval as a CPU-usage sample.
        previousTicks = nil
        highUsageStartedAt = nil
        lowUsageStartedAt = nil
    }

    private func sampleCPU() {
        refreshPowerMode()
        guard let ticks = readCPUTicks() else { return }
        defer { previousTicks = ticks }
        guard let previousTicks else { return }
        // Protect against a host counter rollover or reset causing unsigned underflow.
        guard ticks.total >= previousTicks.total, ticks.busy >= previousTicks.busy else { return }
        let totalDelta = ticks.total - previousTicks.total
        let busyDelta = ticks.busy - previousTicks.busy
        guard totalDelta > 0 else { return }
        usagePercent = min(max(Double(busyDelta) / Double(totalDelta) * 100, 0), 100)
        updateGait(at: Date())
    }

    private func refreshPowerMode() {
        let current = ProcessInfo.processInfo.isLowPowerModeEnabled
        guard current != isLowPowerModeEnabled else { return }
        isLowPowerModeEnabled = current
        scheduleSamplingTimer()
    }

    private func scheduleSamplingTimer() {
        timer?.invalidate()
        let interval: TimeInterval = isLowPowerModeEnabled ? 10 : 2
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            // The timer is installed on the main run loop, so this is actor-safe
            // without creating a new task on every sampling tick.
            MainActor.assumeIsolated { self?.sampleCPU() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func updateGait(at now: Date) {
        if gait == .walking {
            lowUsageStartedAt = nil
            guard usagePercent > threshold else { highUsageStartedAt = nil; return }
            if highUsageStartedAt == nil { highUsageStartedAt = now }
            if let started = highUsageStartedAt, now.timeIntervalSince(started) >= 3 { gait = .running; highUsageStartedAt = nil }
        } else {
            highUsageStartedAt = nil
            guard usagePercent <= threshold else { lowUsageStartedAt = nil; return }
            if lowUsageStartedAt == nil { lowUsageStartedAt = now }
            if let started = lowUsageStartedAt, now.timeIntervalSince(started) >= 10 { gait = .walking; lowUsageStartedAt = nil }
        }
    }

    private func readCPUTicks() -> CPUTicks? {
        var cpuInfo: processor_info_array_t?
        var processorCount: natural_t = 0
        var infoCount: mach_msg_type_number_t = 0
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &processorCount, &cpuInfo, &infoCount)
        guard result == KERN_SUCCESS, let cpuInfo else { return nil }
        defer { vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(infoCount) * vm_size_t(MemoryLayout<integer_t>.stride)) }

        var ticks = CPUTicks()
        let stride = Int(CPU_STATE_MAX)
        for cpu in 0..<Int(processorCount) {
            let offset = cpu * stride
            ticks.user += UInt64(cpuInfo[offset + Int(CPU_STATE_USER)])
            ticks.system += UInt64(cpuInfo[offset + Int(CPU_STATE_SYSTEM)])
            ticks.nice += UInt64(cpuInfo[offset + Int(CPU_STATE_NICE)])
            ticks.idle += UInt64(cpuInfo[offset + Int(CPU_STATE_IDLE)])
        }
        return ticks
    }
}

private struct CPUTicks {
    var user: UInt64 = 0
    var system: UInt64 = 0
    var nice: UInt64 = 0
    var idle: UInt64 = 0
    var busy: UInt64 { user + system + nice }
    var total: UInt64 { busy + idle }
}
