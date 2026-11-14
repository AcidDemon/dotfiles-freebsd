pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../notifications/Todo.js" as Todo

Singleton {
    id: root

    readonly property var items: saved.items
    readonly property var sorted: Todo.sortTodos(items)
    readonly property string today: Todo.toIso(clock.date)
    readonly property var marks: Todo.dueMarks(items, today)

    // once a day, from this hour on; a shell started later still reminds
    readonly property int reminderHour: 8

    property bool ready: false

    function remind() {
        // writing before the file is read would save an empty list over it
        if (!ready) return;
        if (clock.date.getHours() < reminderHour || saved.lastReminder === today) return;
        saved.lastReminder = today;
        file.writeAdapter();
        const due = Todo.dueToday(items, today);
        if (due.length === 0) return;
        const title = due.length === 1 ? "1 to do due" : `${due.length} to dos due`;
        Quickshell.execDetached([Tools.notifySend, "-a", "To Do", title, Todo.reminderBody(due, today)]);
    }

    function store(next) {
        saved.items = next;
        file.writeAdapter();
    }

    function add(text, due) {
        store(items.concat({ id: Todo.nextId(items), text: text, due: due, done: false }));
    }

    function toggle(id) {
        store(items.map(item => item.id === id ? Object.assign({}, item, { done: !item.done }) : item));
    }

    function remove(id) {
        store(items.filter(item => item.id !== id));
    }

    function clearDone() {
        store(items.filter(item => !item.done));
    }

    SystemClock {
        id: clock

        precision: SystemClock.Hours
        onDateChanged: root.remind()
    }


    FileView {
        id: file

        path: Quickshell.statePath("todos.json")
        blockLoading: true
        blockWrites: true
        printErrors: false
        onLoaded: {
            root.ready = true;
            root.remind();
        }
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound) return;
            root.ready = true;
            root.remind();
        }

        JsonAdapter {
            id: saved

            property var items: []
            property string lastReminder: ""
        }
    }
}
