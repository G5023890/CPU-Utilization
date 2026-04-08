import Darwin

protocol CPUUsageProviding {
    func prime()
    func sampleUsage() -> Double?
}

final class MachCPUUsageProvider: CPUUsageProviding {
    private var previousTicks: CPUUsageTicks?

    func prime() {
        previousTicks = sampleTicks()
    }

    func sampleUsage() -> Double? {
        guard let current = sampleTicks() else {
            return nil
        }

        defer {
            previousTicks = current
        }

        guard let previousTicks else {
            return nil
        }

        let userDelta = current.user &- previousTicks.user
        let systemDelta = current.system &- previousTicks.system
        let idleDelta = current.idle &- previousTicks.idle
        let niceDelta = current.nice &- previousTicks.nice

        let totalDelta = userDelta &+ systemDelta &+ idleDelta &+ niceDelta
        guard totalDelta > 0 else {
            return nil
        }

        let activeDelta = totalDelta &- idleDelta
        return Double(activeDelta) / Double(totalDelta)
    }

    private func sampleTicks() -> CPUUsageTicks? {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, reboundPointer, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return nil
        }

        return CPUUsageTicks(
            user: UInt64(info.cpu_ticks.0),
            system: UInt64(info.cpu_ticks.1),
            idle: UInt64(info.cpu_ticks.2),
            nice: UInt64(info.cpu_ticks.3)
        )
    }
}

private struct CPUUsageTicks {
    let user: UInt64
    let system: UInt64
    let idle: UInt64
    let nice: UInt64
}
