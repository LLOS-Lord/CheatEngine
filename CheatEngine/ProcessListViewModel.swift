import Foundation

class ProcessListViewModel: ObservableObject {
    @Published var processes: [ProcessInfo] = []
    @Published var selectedPID: Int = -1
    
    func refresh() {
        processes = ProcessHelper.runningProcesses()
            .sorted { $0.name < $1.name }
    }
}