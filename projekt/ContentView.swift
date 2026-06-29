import SwiftUI

struct TodoItem: Codable, Identifiable {
    var id = UUID()
    var title: String
    var isDone = false
}

struct TaskGroup: Codable, Identifiable {
    var id = UUID()
    var name: String
    var tasks: [TodoItem]
}

struct ContentView: View {
    @AppStorage("groups") private var groupsData: Data = Data()
    @State private var groups: [TaskGroup] = []
    @State private var selectedGroup: TaskGroup.ID?
    @State private var newGroupName = ""
    @State private var newTaskTitle = ""

    var body: some View {
        NavigationView {
            // Sidebar
            List(selection: $selectedGroup) {
                ForEach(groups) { group in
                    HStack {
                        Image(systemName: "list.bullet")
                        Text(group.name)
                        Spacer()
                        Text("\(group.tasks.count)")
                            .foregroundColor(.secondary)
                    }
                    .tag(group.id)
                    .contextMenu {
                        Button("Delete list", role: .destructive) {
                            deleteGroup(group.id)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        let id = groups[index].id
                        groups.remove(at: index)
                        if selectedGroup == id {
                            selectedGroup = groups.first?.id
                        }
                    }
                    save()
                }

                HStack {
                    TextField("New list...", text: $newGroupName)
                        .textFieldStyle(.plain)
                    Button("+") {
                        guard !newGroupName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let group = TaskGroup(name: newGroupName, tasks: [])
                        groups.append(group)
                        selectedGroup = group.id
                        newGroupName = ""
                        save()
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200)
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem {
                    Button {
                        if let id = selectedGroup {
                            deleteGroup(id)
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(selectedGroup == nil)
                }
            }

            // Detail – tasks in selected group
            if let selectedGroup = selectedGroup,
               let index = groups.firstIndex(where: { $0.id == selectedGroup }) {
                VStack {
                    List {
                        ForEach($groups[index].tasks) { $task in
                            HStack {
                                Button {
                                    task.isDone.toggle()
                                    save()
                                } label: {
                                    Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                }
                                Text(task.title)
                                    .strikethrough(task.isDone)
                                Spacer()
                                Button {
                                    deleteTask(in: groups[index].id, task: task.id)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .contextMenu {
                                Button("Delete task", role: .destructive) {
                                    deleteTask(in: groups[index].id, task: task.id)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            groups[index].tasks.remove(atOffsets: indexSet)
                            save()
                        }
                    }

                    HStack {
                        TextField("New task...", text: $newTaskTitle)
                            .textFieldStyle(.roundedBorder)
                        Button("Add") {
                            guard !newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            groups[index].tasks.append(TodoItem(title: newTaskTitle))
                            newTaskTitle = ""
                            save()
                        }
                    }
                    .padding()
                }
                .navigationTitle(groups[index].name)
            } else {
                Text("Select a list")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear(perform: load)
    }

    private func deleteGroup(_ id: TaskGroup.ID) {
        groups.removeAll { $0.id == id }
        if selectedGroup == id {
            selectedGroup = groups.first?.id
        }
        save()
    }

    private func deleteTask(in groupId: TaskGroup.ID, task taskId: TodoItem.ID) {
        guard let index = groups.firstIndex(where: { $0.id == groupId }) else { return }
        groups[index].tasks.removeAll { $0.id == taskId }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(groups) {
            groupsData = data
        }
    }

    private func load() {
        if let decoded = try? JSONDecoder().decode([TaskGroup].self, from: groupsData) {
            groups = decoded
        }
    }
}
