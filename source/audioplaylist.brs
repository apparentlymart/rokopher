
Sub HandleAudioPlaylist(elem, port)

    print "Preparing to show an audio playlist"

    attr = elem.GetAttributes()

    data = {}
    data.imagestyle = attr.imagestyle
    data.title = attr.title
    data.parenttitle = attr.parenttitle
    data.items = RestrictedContentMetadataArrayFromXMLList(elem.GetChildElements(), [
        "song", "genericaudio"
    ])

    RunAudioPlayer(data, port)

End Sub

Sub RunAudioPlayer(data, port)

    print "Preparing to show a springboard screen as an audio player"

    screen = CreateObject("roSpringboardScreen")
    screen.SetDescriptionStyle("audio")

    If data.title <> invalid Then
        If data.parenttitle <> invalid Then
           screen.SetBreadcrumbText(data.parenttitle, data.title)
        Else
           screen.SetBreadcrumbText(data.title, "")
        End If
    End If

    ' FIXME: Implement a progress indicator
    ' But the Roku doesn't actually provide any instrumentation
    ' for this so it'll be a hack.
    screen.SetProgressIndicatorEnabled(false)
    'screen.SetProgressIndicator(50, 100)

    player = CreateObject("roAudioPlayer")
    player.SetContentList(data.items)

    player.SetMessagePort(port)
    screen.SetMessagePort(port)
    screen.Show()

    player.Play()

    selectedidx = invalid

    While true
        msg = wait(0, port)
        msgtype = type(msg)

        If msgtype = "roSpringboardScreenEvent" Then
           If msg.isScreenClosed() Then
               Exit While
           Else If msg.isButtonPressed() Then
           End If
        Else If msgtype = "roAudioPlayerEvent" Then
           If msg.IsStatusMessage() Then
              print "Player Status: " + msg.GetMessage()
           Else If msg.isListitemSelected() Then
              selectedidx = msg.GetIndex()
              print "Starting to play item " + Str(selectedidx)
              item = data.items[selectedidx]
              screen.SetContent(item)
              screen.Show()
           Else If msg.IsRequestFailed() Then
              print "Audio request failed. Skipping to next track."
              newidx = selectedidx + 1
              If newidx >= data.items.Count() Then newidx = 0
              player.SetNext(newidx)
           Else
              print "Unhandled audio player event " + Str(msg.GetType())
           End If
        End If
    End While

End Sub
