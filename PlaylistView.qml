import QtQuick 2.1

Item {
    id: root
    width: 300
    height: 500

    property string type: "local" // local or network
    property int actualWidth: listview.contentWidth
    property int actualHeight: listview.contentHeight

    property var childrenItems: []

    property string content: JSON.stringify([{"itemName": "1.mp4",
                                              "itemUrl": "/home/hualet/Videos/1.mp4",
                                              "itemChild": "[]"},
                                             {"itemName": "Three",
                                              "itemUrl": "",
                                              "itemChild": JSON.stringify([{"itemName": "Two",
                                                                            "itemUrl": "",
                                                                            "itemChild": JSON.stringify([{"itemName": "Movie.mkv",
                                                                                                          "itemUrl": "/home/hualet/Videos/Movie.mkv",
                                                                                                          "itemChild": "[]"},
                                                                                                         {"itemName": "slime.mov",
                                                                                                          "itemUrl": "/home/hualet/Videos/slime.mov",
                                                                                                          "itemChild": "[]"}])}])},
                                             {"itemName": "Two",
                                              "itemUrl": "",
                                              "itemChild": JSON.stringify([{"itemName": "One",
                                                                            "itemUrl": "",
                                                                            "itemChild": "[]"}])}])

    Component {
        id: listview_delegate

        Item {
            id: item

            width: root.width
            height: 20

            property int itemIndex: index
            property alias child: column.child
            property string title: itemName

            Behavior on height {
                SmoothedAnimation {duration: 100}
            }

            Component.onCompleted: {
                print("push =====>", itemName)
                ListView.view.parent.childrenItems.push(item)
            }

            function increaseH(h) {
                height += h
                if (ListView.view &&
                    ListView.view.parent.parent &&
                    ListView.view.parent.parent.parent &&
                    ListView.view.parent.parent.parent.increaseH) {
                    ListView.view.parent.parent.parent.increaseH(h)
                }
            }

            function decreaseH(h) {
                height -= h
                if (ListView.view &&
                    ListView.view.parent.parent &&
                    ListView.view.parent.parent.parent &&
                    ListView.view.parent.parent.parent.decreaseH) {
                    ListView.view.parent.parent.parent.decreaseH(h)
                }
            }

            function isGroup() {
                /* print(itemName + "===>" + itemChild) */
                return itemChild != "[]"
            }

            Column {
                id: column

                property var child

                anchors.fill: parent
                anchors.leftMargin: 15
                anchors.topMargin: 5

                function toggleExpand() {
                    item.ListView.view.currentIndex = index
                    if (!column.parent.isGroup()) playlist.currentItem = column

                    if (column.child) {
                        column.child.destroy();
                        column.parent.decreaseH(column.child.actualHeight)
                    } else if (column.parent.isGroup()) {
                        column.child = Qt.createQmlObject('import QtQuick 2.1; PlaylistView{width:' + (column.width) + '}',
                                                          column, "child")
                        column.child.content = itemChild
                        column.child.anchors.left = column.left

                        column.parent.increaseH(column.child.actualHeight)
                    } else {
                        /* print(itemName) */
                        /* print(itemUrl) */
                        playlist.videoSelected(itemUrl)
                    }
                }

                Item {
                    width: parent.width
                    height: row.height

                    MouseArea {
                        id: mouse_area
                        hoverEnabled: true
                        anchors.fill: parent

                        onEntered: {
                            playlist.state = "active"
                            delete_button.visible = true

                            if (!column.parent.isGroup()) {
                                var pos = windowView.getCursorPos()
                                tooltip.showTip(pos.x, pos.y, itemName)
                            }
                        }
                        onExited: {
                            delete_button.visible = false
                            tooltip.hideTip()
                        }
                        onClicked: column.toggleExpand()
                    }

                    Row {
                        id: row
                        spacing: 10

                        Image {
                            opacity: column.parent.isGroup() ? 1 : 0
                            source: column.child ? "image/expanded.png" : "image/not_expanded.png"
                        }

                        Text {
                            id: label
                            text: itemName
                            color: column.child ? "#8800BDFF" : playlist.currentItem == column ? "#00BDFF" : mouse_area.containsMouse ? "white" : "#B4B4B4"
                            font.pixelSize: column.parent.isGroup() ? 12 : playlist.currentItem == column ? 13 : 11
                        }
                    }

                    Image {
                        id: delete_button
                        visible: false
                        source: "image/delete_normal.png"
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            hoverEnabled: true
                            anchors.fill: parent

                            onEntered: {
                                playlist.state = "active"
                                delete_button.visible = true
                                delete_button.source = "image/delete_hover.png"
                            }
                            onExited: {
                                delete_button.visible = false
                                delete_button.source = "image/delete_normal.png"
                            }
                            onPressed: delete_button.source = "image/delete_pressed.png"
                            onReleased: delete_button.source = "image/delete_hover.png"
                        }
                    }
                }
            }
        }
    }

    ListView {
        id: listview

        model: root.getModelFromString(root.content, listview)
        delegate: listview_delegate
        currentIndex: -1

        anchors.fill: parent
    }

    // getContent returns the string representation of this playlist hierarchy
    // getObject returns the object representation of this playlist hierarchy
    function getContent() {
        var result = []
        for (var i = 0; i < listview.count; i++) {
            result.push(listview.model.get(i))
        }
        return JSON.stringify(result)
    }

    function getObject() {
        return contentToObject(getContent())
    }

    function contentToObject(content) {
        var result = []

        if (!content || content == "") return result
        var items = JSON.parse(content)
        for (var i = 0; i < items.length; i++) {
            items[i].itemChild = contentToObject(items[i].itemChild)
            result.push(items[i])
        }

        return result
    }

    function objectToContent(obj) {
        if (!obj) return "[]"

        var result = []

        for (var i = 0; i < obj.length; i++) {
            var item = {}
            item.itemName = obj[i].itemName
            item.itemChild = objectToContent(obj[i].itemChild)
            result.push(item)
        }

        return JSON.stringify(result)
    }

    // Just this level
    function getItemByName(name) {
        print("getItemByName")
        for (var i = 0; i < childrenItems.length; i++) {
            if (childrenItems[i].title == name) {
                return childrenItems[i]
            }
        }

        return null
    }

    /* Database operations */
    // path is something like ["level one", "level two", "level three"]
    function _insert(path) {
        var lastMatchItem = root
        for (var i = 0; i < path.length; i++) {
            var item = lastMatchItem.getItemByName(path[i])
            if (item != null) {
                if (item.child) {
                    lastMatchItem = item.child
                } else {
                    return lastMatchItem.insertToContent(path[i],
                                                         path.slice(i + 1,
                                                                    path.length))
                }
            } else {
                return lastMatchItem.insertToListModel(path.slice(i, path.length))
            }
        }
    }

    function _delete(path) {
        var lastMatchItem = root
        for (var i = 0; i < path.length - 1; i++) {
            var item = lastMatchItem.getItemByName(path[i])
            if (item != null) {
                if (item.child) {
                    lastMatchItem = item.child
                } else {
                    return lastMatchItem.deleteFromContent(path[i],
                                                           path.slice(i + 1, path.length))
                }
            } else {
                return
            }
        }

        if(lastMatchItem && lastMatchItem.getItemByName(path[path.length - 1])) {
            lastMatchItem.deleteFromListModel(path[path.length - 1])
        }
    }

    function _save() {
        if (type == "local") {
            database.playlist_local = getContent()
        }
    }

    function _fetch() {
        return type == "local" ? database.playlist_local : database.playlist_network
    }
    
    /* Database operations end */

    // see `insert' above for more infomation about path
    function pathToListElement(path) {
        var result

        for (var i = path.length - 1; i >= 0; i--) {
            var ele = {}
            ele.itemName = path[i]
            ele.itemUrl = path[i]
            ele.itemChild = result ? JSON.stringify([result]) : "[]"
            result = ele
        }

        return result
    }

    function insertToListModel(path) {
        listview.model.append(pathToListElement(path))
        listview.forceLayout()
    }

    function insertToContent(parentNode, path) {
        var obj = getObject()
        for (var i = 0; i < obj.length; i++) {
            if (obj[i].itemName == parentNode) {
                var parent = obj[i]

                for (var i = 0; i < path.length; i++) {
                    var child = parent.itemChild
                    var flag = false
                    for (var j = 0; j < child.length; j++) {
                        var c = child[i]
                        if (c && c.itemName == path[i]) {
                            flag = true
                            parent = c
                            break
                        }
                    }
                    if (!flag) {
                        parent.itemChild.push(pathToListElement(path.slice(i, path.length)))
                    }
                }
                break
            }
        }
        content = objectToContent(obj)
    }

    function deleteFromListModel(name) {
        for (var i = 0; i < listview.count; i++) {
            if (listview.model.get(i).itemName == name) {
                listview.model.remove(i, 1)
            }
        }
    }

    function deleteFromContent(parentNode, path) {
        var obj = getObject()
        for (var i = 0; i < obj.length; i++) {
            if (obj[i].itemName == parentNode) {
                var parent = obj[i]

                for (var i = 0; i < path.length - 1; i++) {
                    var child = parent.itemChild
                    var flag = false
                    for (var j = 0; j < child.length; j++) {
                        var c = child[i]
                        if (c && c.itemName == path[i]) {
                            flag = true
                            parent = c
                            break
                        }
                    }
                    if (!flag) {
                        break
                    }
                }
                var child = parent.itemChild
                for (var j = 0; j < child.length; j++) {
                    var c = child[i]
                    if (c && c.itemName == path[i]) {
                        parent.itemChild.splice(i, 1)
                    }
                }
                break
            }
        }
        content = objectToContent(obj)
    }

    function deleteOne(name) {
        for (var i = 0; i < listview.count; i++) {
            if (listview.model.get(i).itemName == name) {
                listview.model.remove(i, 1)
            }
        }
    }

    function getModelFromString(str, prt) {
        var model = Qt.createQmlObject('import QtQuick 2.1; ListModel{}',
                                       prt, "model")
        if (str != "") {
            var obj = JSON.parse(str)

            for (var i = 0; i < obj.length; i++) {
                model.append({"itemName": obj[i].itemName,
                              "itemChild": obj[i].itemChild,
                              "itemUrl": obj[i].itemUrl} )
            }
        }

        return model
    }

    Component.onCompleted: {
        /* _insert(["Three", "Two", "Four"]); */
        /* _delete(["Three", "Two", "One"]); */
         /* print(objectToContent(contentToObject(content))) */
     }
}