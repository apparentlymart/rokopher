
Sub HandleItemDetail(elem, port)

    print "Preparing to show an item detail"

    attr = elem.GetAttributes()

    data = {}
    data.title = attr.title
    data.parenttitle = attr.parenttitle
    data.imagestyle = attr.imagestyle

    items = ContentMetadataArrayFromXMLList(elem.GetChildElements())
    If items.Count() > 0 Then
        data.item = items[0]
    Else
        data.item = {}
    End If

    data.actionchoices = []
    actionchoiceelems = elem.GetNamedElements("actionchoice")
    For Each actionchoiceelem In actionchoiceelems
        actionid = actionchoiceelem.GetAttributes().id
        actioncaption = actionchoiceelem.GetAttributes().caption
        actionchoice = {
            id: actionid,
            caption: actioncaption
        }
        data.actionchoices.Push(actionchoice)
    End For

    RunSpringboardScreen(data, port)

End Sub

Sub RunSpringboardScreen(data, port)

    print "Preparing to show a springboard screen"

    screen = CreateObject("roSpringboardScreen")
    screen.SetContent(data.item)

    If data.title <> invalid Then
        If data.parenttitle <> invalid Then
           screen.SetBreadcrumbText(data.parenttitle, data.title)
        Else
           screen.SetBreadcrumbText(data.title, "")
        End If
    End If

    If data.imagestyle <> invalid Then screen.SetDisplayMode(data.imagestyle)

    For choiceidx = 0 to data.actionchoices.Count()-1
        actionchoice = data.actionchoices[choiceidx]
        selectaction = data.item.rokopherActions[actionchoice.id]
        If selectaction <> invalid Then
            screen.AddButton(choiceidx, actionchoice.caption)
        End If
    End For

    screen.SetMessagePort(port)
    screen.Show()

    While true
        msg = wait(0, port)
        msgtype = type(msg)

        If msgtype = "roSpringboardScreenEvent" Then
           If msg.isScreenClosed() Then
               Exit While
           Else If msg.isButtonPressed() Then
               actionchoiceidx = msg.GetIndex()
               actionchoice = data.actionchoices[actionchoiceidx]
               action = data.item.rokopherActions[actionchoice.id]
               ' print "Activating the " + action.id + " action"
               ' TODO: Support method=POST
               Navigate(action.url, port)
           End If
        End If
    End While

End Sub

