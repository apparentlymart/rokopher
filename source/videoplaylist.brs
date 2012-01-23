
Sub HandleVideoPlaylist(elem, port)

    print "Preparing to show a video playlist"

    attr = elem.GetAttributes()

    data = {}
    data.imagestyle = attr.imagestyle
    data.title = attr.title
    data.parenttitle = attr.parenttitle
    data.items = RestrictedContentMetadataArrayFromXMLList(elem.GetChildElements(), [
        "movie", "episode", "genericvideo", "livevideo"
    ])

    RunVideoPlayer(data, port)

End Sub

Sub RunVideoPlayer(data, port)

    print "Preparing to show a video screen"

    screen = CreateObject("roVideoScreen")

    screen.SetContent(data.items[0])

    screen.SetMessagePort(port)
    screen.Show()

    While true
        print "waiting for a message"
        msg = wait(0, port)
        msgtype = type(msg)

        print "Got a " + msgtype

        If msgtype = "roVideoScreenEvent" Then
           If msg.isScreenClosed() Then
               Exit While
           Else If msg.IsStatusMessage() Then
               print "Video player status: " + msg.GetMessage()
           Else If msg.IsRequestFailed() Then
               print "Video request failed: " + msg.GetMessage()
           End If
        End If
    End While

End Sub

