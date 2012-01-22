
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

    screen.SetMessagePort(port)
    screen.Show()

    While true
        msg = wait(0, port)
        msgtype = type(msg)

        If msgtype = "roSpringboardScreenEvent" Then
           If msg.isScreenClosed() Then
               Exit While
           End If
        End If
    End While

End Sub

