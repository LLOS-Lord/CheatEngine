import Foundation

class ProcessListViewModel: ObservableObject {
    @Published var processes: [RunningProcessInfo] = []
    @Published var selectedPID: Int = -1
    @Published var lastError: String? = nil
    
    func refresh() {
        let procs = ProcessHelper.runningProcesses()
        processes = procs.sorted { $0.name < $1.name }
        lastError = processes.isEmpty ? "Không tìm thấy tiến trình nào. Kiểm tra quyền?" : nil
    }
}