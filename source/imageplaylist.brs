
Sub HandleImagePlaylist(elem, port)

    print "Preparing to show an image playlist"

    attr = elem.GetAttributes()

    data = {}
    data.imagestyle = attr.imagestyle
    data.items = RestrictedContentMetadataArrayFromXMLList(elem.GetChildElements(), [
        "photo", "genericimage"
    ])

    RunSlideShow(data, port)

End Sub

Sub RunSlideshow(data, port)

    print "Preparing to show a slideshow screen"

    screen = CreateObject("roSlideShow")
    screen.SetContentList(data.items)
    If data.imagestyle <> invalid Then screen.SetDisplayMode(data.imagestyle)

    screen.SetMessagePort(port)
    screen.Show()

    While true
        msg = wait(0, port)
        msgtype = type(msg)

        If msgtype = "roSlideShowEvent" Then
           If msg.isScreenClosed() Then
               Exit While
           End If
        End If
    End While

End Sub
