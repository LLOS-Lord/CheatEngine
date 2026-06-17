import Foundation

struct MemoryResultItem: Identifiable {
    let id = UUID()
    let address: UInt64
    let value: Any
}

class MemoryScanner: ObservableObject {
    @Published var results: [MemoryResultItem] = []
    @Published var statusDetail: String = ""
    private var currentTask: mach_port_t = 0
    private var currentPID: Int = -1
    
    func attach(to pid: Int) -> Bool {
        var task: mach_port_t = 0
        let kr = MemoryEngine.getTaskPort(forPID: Int32(pid), taskPort: &task)
        if kr == KERN_SUCCESS {
            currentTask = task
            currentPID = pid
            statusDetail = "Đã lấy task port cho PID \(pid)"
            return true
        } else {
            statusDetail = "Lỗi task_for_pid: \(kr) (PID \(pid)). Cần quyền com.apple.system-task-ports?"
            return false
        }
    }
    
    func scan(type: ScanDataType, value: Any) {
        guard currentTask != 0 else {
            statusDetail = "Chưa kết nối tiến trình nào"
            return
        }
        statusDetail = "Đang quét bộ nhớ..."
        DispatchQueue.global(qos: .userInitiated).async {
            if let rawResults = MemoryEngine.scanMemory(ofTask: self.currentTask,
                                                        dataType: type,
                                                        targetValue: value) {
                var items: [MemoryResultItem] = []
                for r in rawResults {
                    items.append(MemoryResultItem(address: r.address, value: r.value ?? 0))
                }
                DispatchQueue.main.async {
                    self.results = items
                    self.statusDetail = "Tìm thấy \(items.count) địa chỉ"
                }
            } else {
                DispatchQueue.main.async {
                    self.results = []
                    self.statusDetail = "Quét thất bại (có thể không đọc được bộ nhớ)"
                }
            }
        }
    }
    
    func writeInt32(address: UInt64, newValue: Int32) {
        guard currentTask != 0 else { return }
        let kr = MemoryEngine.writeInt32(toTask: currentTask, address: address, value: newValue)
        statusDetail = "Ghi Int32: \(kr == KERN_SUCCESS ? "OK" : "Lỗi \(kr)")"
    }
    
    func writeFloat(address: UInt64, newValue: Float) {
        guard currentTask != 0 else { return }
        let kr = MemoryEngine.writeFloat(toTask: currentTask, address: address, value: newValue)
        statusDetail = "Ghi Float: \(kr == KERN_SUCCESS ? "OK" : "Lỗi \(kr)")"
    }
}