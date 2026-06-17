import Foundation

struct MemoryResultItem: Identifiable {
    let id = UUID()
    let address: UInt64
    let value: Any
}

class MemoryScanner: ObservableObject {
    @Published var results: [MemoryResultItem] = []
    private var currentTask: mach_port_t = 0
    private var currentPID: Int = -1
    
    func attach(to pid: Int) -> Bool {
        var task: mach_port_t = 0
        let kr = MemoryEngine.getTaskPort(forPID: Int32(pid), taskPort: &task)
        if kr == KERN_SUCCESS {
            currentTask = task
            currentPID = pid
            return true
        }
        return false
    }
    
    func scan(type: ScanDataType, value: Any) {
        guard currentTask != 0 else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let rawResults = MemoryEngine.scanMemory(ofTask: self.currentTask,
                                                     dataType: type,
                                                     targetValue: value)
            var items: [MemoryResultItem] = []
            for r in rawResults {
                items.append(MemoryResultItem(address: r.address, value: r.value ?? 0))
            }
            DispatchQueue.main.async {
                self.results = items
            }
        }
    }
    
    func writeInt32(address: UInt64, newValue: Int32) {
        guard currentTask != 0 else { return }
        _ = MemoryEngine.writeInt32(toTask: currentTask, address: address, value: newValue)
    }
    
    func writeFloat(address: UInt64, newValue: Float) {
        guard currentTask != 0 else { return }
        _ = MemoryEngine.writeFloat(toTask: currentTask, address: address, value: newValue)
    }
}