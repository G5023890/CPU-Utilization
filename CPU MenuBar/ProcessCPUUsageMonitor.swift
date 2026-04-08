import Foundation
import Darwin

struct ProcessCPUUsageItem: Identifiable, Equatable {
    let pid: pid_t
    let name: String
    let cpuPercent: Double

    var id: pid_t {
        pid
    }
}

@MainActor
protocol ProcessCPUUsageProviding {
    func start()
    func stop()
    func refresh()
    func topProcesses(limit: Int) -> [ProcessCPUUsageItem]
}

@MainActor
final class ProcessCPUUsageMonitor: NSObject, ProcessCPUUsageProviding {
    private struct SnapshotSample {
        let cpuTime: UInt64
        let name: String
        let isSystem: Bool
    }

    private struct Snapshot {
        let timestamp: UInt64
        let samples: [pid_t: SnapshotSample]
    }

    private var previousSnapshot: Snapshot?
    private var latestItems: [ProcessCPUUsageItem] = []
    private var latestTotalCpuPercent: Double?
    private var processNameCache: [pid_t: String] = [:]
    private let totalUsageProvider: CPUUsageProviding
    private var timer: Timer?
    private let refreshInterval: TimeInterval = 1
    private let topProcessLimit = 10
    private let aggregateRemainderThreshold = 0.05

    var onChange: (() -> Void)?

    init(totalUsageProvider: CPUUsageProviding = MachCPUUsageProvider()) {
        self.totalUsageProvider = totalUsageProvider
        super.init()
    }

    func start() {
        guard timer == nil else {
            return
        }

        processNameCache.removeAll(keepingCapacity: true)
        totalUsageProvider.prime()
        prime()
        refresh(notifyChange: false)

        let timer = Timer(
            timeInterval: refreshInterval,
            target: self,
            selector: #selector(handleTimerTick),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() {
        refresh(notifyChange: true)
    }

    @objc
    private func handleTimerTick() {
        refresh(notifyChange: true)
    }

    private func refresh(notifyChange: Bool) {
        guard let current = captureSnapshot() else {
            return
        }

        defer {
            previousSnapshot = current
        }

        guard let previousSnapshot else {
            return
        }

        guard let totalUsage = totalUsageProvider.sampleUsage() else {
            return
        }

        let elapsed = current.timestamp &- previousSnapshot.timestamp
        guard elapsed > 0 else {
            return
        }

        let totalCpuPercent = max(0, min(100, totalUsage * 100.0))

        var userItems: [ProcessCPUUsageItem] = []
        userItems.reserveCapacity(current.samples.count)
        var systemCpuPercent: Double = 0

        for (pid, currentSample) in current.samples {
            guard let previousSample = previousSnapshot.samples[pid] else {
                continue
            }

            let cpuDelta = currentSample.cpuTime >= previousSample.cpuTime
                ? currentSample.cpuTime &- previousSample.cpuTime
                : 0

            let cpuPercent = Double(cpuDelta) / Double(elapsed) * 100.0
            guard cpuPercent >= 0 else {
                continue
            }

            if currentSample.isSystem {
                systemCpuPercent += cpuPercent
            } else {
                userItems.append(
                    ProcessCPUUsageItem(
                        pid: pid,
                        name: currentSample.name,
                        cpuPercent: cpuPercent
                    )
                )
            }
        }

        let rawTotalCpuPercent = userItems.reduce(systemCpuPercent) { $0 + $1.cpuPercent }
        latestTotalCpuPercent = totalCpuPercent
        var includesOther = false
        var visibleUserItems: [ProcessCPUUsageItem] = []

        while true {
            let aggregateCount = (systemCpuPercent > 0 ? 1 : 0) + (includesOther ? 1 : 0)
            let visibleUserLimit = max(0, topProcessLimit - aggregateCount)
            visibleUserItems = selectTopProcesses(from: userItems, limit: visibleUserLimit)

            let displayedCpuPercent = visibleUserItems.reduce(systemCpuPercent) { $0 + $1.cpuPercent }
            let missingCpuPercent = max(0, rawTotalCpuPercent - displayedCpuPercent)
            let needsOther = missingCpuPercent >= aggregateRemainderThreshold

            if needsOther == includesOther {
                break
            }

            includesOther = needsOther
        }

        var aggregateItems: [ProcessCPUUsageItem] = []
        if systemCpuPercent > 0 {
            aggregateItems.append(
                ProcessCPUUsageItem(
                    pid: 0,
                    name: "System processes",
                    cpuPercent: systemCpuPercent
                )
            )
        }

        if includesOther {
            let displayedCpuPercent = visibleUserItems.reduce(systemCpuPercent) { $0 + $1.cpuPercent }
            let missingCpuPercent = max(0, rawTotalCpuPercent - displayedCpuPercent)
            aggregateItems.append(
                ProcessCPUUsageItem(
                    pid: -1,
                    name: "Other processes",
                    cpuPercent: missingCpuPercent
                )
            )
        }

        var displayItems = visibleUserItems
        displayItems.append(contentsOf: aggregateItems)

        let scale = rawTotalCpuPercent > 0 ? totalCpuPercent / rawTotalCpuPercent : 1
        latestItems = selectTopProcesses(
            from: displayItems.map { item in
                ProcessCPUUsageItem(
                    pid: item.pid,
                    name: item.name,
                    cpuPercent: item.cpuPercent * scale
                )
            },
            limit: topProcessLimit
        )

        pruneNameCache(using: current.samples)

        if notifyChange {
            onChange?()
        }
    }

    func topProcesses(limit: Int) -> [ProcessCPUUsageItem] {
        guard limit > 0 else {
            return []
        }

        return Array(latestItems.prefix(limit))
    }

    func totalCPUPercent() -> Double? {
        latestTotalCpuPercent
    }

    private func prime() {
        previousSnapshot = captureSnapshot()
    }

    private func captureSnapshot() -> Snapshot? {
        let pids = listPIDs()
        guard !pids.isEmpty else {
            return nil
        }

        var samples: [pid_t: SnapshotSample] = [:]
        samples.reserveCapacity(pids.count)

        for pid in pids where pid > 0 {
            guard let sample = captureSample(for: pid) else {
                continue
            }

            samples[pid] = sample
        }

        return Snapshot(timestamp: DispatchTime.now().uptimeNanoseconds, samples: samples)
    }

    private func listPIDs() -> [pid_t] {
        let initialBytes = proc_listallpids(nil, 0)
        guard initialBytes > 0 else {
            return []
        }

        let stride = MemoryLayout<pid_t>.stride
        let capacity = max(1024, Int(initialBytes) / stride + 256)
        var pids = [pid_t](repeating: 0, count: capacity)

        let writtenBytes = proc_listallpids(&pids, Int32(pids.count * stride))
        guard writtenBytes > 0 else {
            return []
        }

        let actualCount = min(pids.count, Int(writtenBytes) / stride)
        return Array(pids.prefix(actualCount))
    }

    private func captureSample(for pid: pid_t) -> SnapshotSample? {
        var taskInfo = proc_taskinfo()
        let taskInfoResult = proc_pidinfo(
            pid,
            PROC_PIDTASKINFO,
            0,
            &taskInfo,
            Int32(MemoryLayout<proc_taskinfo>.size)
        )

        guard taskInfoResult == MemoryLayout<proc_taskinfo>.size else {
            return nil
        }

        var bsdInfo = proc_bsdinfo()
        let bsdInfoResult = proc_pidinfo(
            pid,
            PROC_PIDTBSDINFO,
            0,
            &bsdInfo,
            Int32(MemoryLayout<proc_bsdinfo>.size)
        )

        guard bsdInfoResult == MemoryLayout<proc_bsdinfo>.size else {
            return nil
        }

        let cpuTime = taskInfo.pti_total_user &+ taskInfo.pti_total_system
        let isSystem = (bsdInfo.pbi_flags & UInt32(PROC_FLAG_SYSTEM)) != 0

        if let cachedName = processNameCache[pid] {
            return SnapshotSample(cpuTime: cpuTime, name: cachedName, isSystem: isSystem)
        }

        if let resolvedName = processName(for: bsdInfo) {
            processNameCache[pid] = resolvedName
            return SnapshotSample(cpuTime: cpuTime, name: resolvedName, isSystem: isSystem)
        }

        return SnapshotSample(cpuTime: cpuTime, name: "PID \(pid)", isSystem: isSystem)
    }

    private func processName(for info: proc_bsdinfo) -> String? {
        if let name = string(from: info.pbi_name) {
            return name
        }

        if let comm = string(from: info.pbi_comm) {
            return comm
        }

        return nil
    }

    private func selectTopProcesses(from items: [ProcessCPUUsageItem], limit: Int) -> [ProcessCPUUsageItem] {
        guard limit > 0 else {
            return []
        }

        var selected: [ProcessCPUUsageItem] = []
        selected.reserveCapacity(min(limit, items.count))

        for item in items {
            insert(item, into: &selected, limit: limit)
        }

        return selected
    }

    private func insert(_ item: ProcessCPUUsageItem, into selected: inout [ProcessCPUUsageItem], limit: Int) {
        guard limit > 0 else {
            return
        }

        var insertIndex = 0
        while insertIndex < selected.count && ranksAhead(selected[insertIndex], of: item) {
            insertIndex += 1
        }

        if selected.count < limit {
            selected.insert(item, at: insertIndex)
            return
        }

        guard insertIndex < limit else {
            return
        }

        selected.insert(item, at: insertIndex)
        selected.removeLast()
    }

    private func ranksAhead(_ lhs: ProcessCPUUsageItem, of rhs: ProcessCPUUsageItem) -> Bool {
        if lhs.cpuPercent != rhs.cpuPercent {
            return lhs.cpuPercent > rhs.cpuPercent
        }

        let nameComparison = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
        if nameComparison != .orderedSame {
            return nameComparison == .orderedAscending
        }

        return lhs.pid < rhs.pid
    }

    private func pruneNameCache(using currentSamples: [pid_t: SnapshotSample]) {
        guard !processNameCache.isEmpty else {
            return
        }

        processNameCache = processNameCache.filter { currentSamples[$0.key] != nil }
    }

    private func string<T>(from cString: T) -> String? {
        withUnsafeBytes(of: cString) { rawBuffer in
            let bytes = rawBuffer.prefix(while: { $0 != 0 })
            guard !bytes.isEmpty else {
                return nil
            }

            let string = String(decoding: bytes, as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return string.isEmpty ? nil : string
        }
    }
}
