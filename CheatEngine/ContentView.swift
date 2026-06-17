import SwiftUI

enum ScanMode: String, CaseIterable {
    case int32 = "Int32"
    case float = "Float"
    case string = "String"
    
    var dataType: ScanDataType {
        switch self {
        case .int32: return .int32
        case .float: return .float
        case .string: return .string
        }
    }
}

struct ContentView: View {
    @StateObject private var procVM = ProcessListViewModel()
    @StateObject private var scanner = MemoryScanner()
    @State private var searchText = ""
    @State private var selectedMode: ScanMode = .int32
    @State private var editValueText = ""
    @State private var statusMessage = "Chưa kết nối"
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Picker("Process", selection: $procVM.selectedPID) {
                        Text("None").tag(-1)
                        ForEach(procVM.processes, id: \.pid) { proc in
                            Text("\(proc.name) (\(proc.pid))").tag(proc.pid)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    Button("Làm mới") { procVM.refresh() }
                }
                .padding()
                
                if procVM.selectedPID != -1 {
                    Button("Kết nối") {
                        if scanner.attach(to: procVM.selectedPID) {
                            statusMessage = "Đã kết nối PID \(procVM.selectedPID)"
                        } else {
                            statusMessage = "Không thể kết nối PID \(procVM.selectedPID)"
                        }
                    }
                }
                
                HStack {
                    TextField("Giá trị tìm", text: $searchText)
                    Picker("Kiểu", selection: $selectedMode) {
                        ForEach(ScanMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    Button("Quét") {
                        guard !searchText.isEmpty else { return }
                        let value: Any
                        switch selectedMode {
                        case .int32:
                            guard let v = Int32(searchText) else { return }
                            value = NSNumber(value: v)
                        case .float:
                            guard let v = Float(searchText) else { return }
                            value = NSNumber(value: v)
                        case .string:
                            value = searchText
                        }
                        scanner.scan(type: selectedMode.dataType, value: value)
                        statusMessage = "Đã quét"
                    }
                }
                .padding()
                
                List {
                    ForEach(scanner.results) { item in
                        HStack {
                            Text(String(format: "0x%llX", item.address))
                            Spacer()
                            Text("\(item.value)")
                        }
                        .onTapGesture {
                            editValueText = "\(item.value)"
                            UserDefaults.standard.set(item.address, forKey: "editAddress")
                            UserDefaults.standard.set(selectedMode.rawValue, forKey: "editMode")
                        }
                    }
                }
                
                HStack {
                    TextField("Giá trị mới", text: $editValueText)
                    Button("Ghi") {
                        guard let addr = UserDefaults.standard.value(forKey: "editAddress") as? UInt64 else { return }
                        let mode = UserDefaults.standard.string(forKey: "editMode") ?? "int32"
                        if mode == "int32", let v = Int32(editValueText) {
                            scanner.writeInt32(address: addr, newValue: v)
                            statusMessage = "Đã ghi Int32"
                        } else if mode == "float", let v = Float(editValueText) {
                            scanner.writeFloat(address: addr, newValue: v)
                            statusMessage = "Đã ghi Float"
                        } else if mode == "string" {
                            statusMessage = "Ghi chuỗi chưa hỗ trợ"
                        }
                    }
                }
                .padding()
                
                Text(statusMessage).font(.caption)
                Text(scanner.statusDetail).font(.caption2).foregroundColor(.gray)  // dòng mới thêm
            }
            .navigationTitle("Cheat Engine iOS")
            .onAppear {
                procVM.refresh()
            }
        }
    }
}