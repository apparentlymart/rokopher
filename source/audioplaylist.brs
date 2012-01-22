
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

    ' NOTE: It's only possible to detect left/right keypresses
    ' if at least one button is added.
    If data.items.Count() > 1 Then
        screen.AllowNavLeft(true)
        screen.AllowNavRight(true)
    End If

    player = CreateObject("roAudioPlayer")
    player.SetContentList(data.items)

    player.SetMessagePort(port)
    screen.SetMessagePort(port)

    player.Play()

    selectedidx = 0

    ' There is some lag before we get the event for playback
    ' starting, so let's populate the screen ahead of time.
    If data.items.Count() > 0 Then
        screen.SetContent(data.items[selectedidx])
    End If
    screen.Show()

    skip = Function (player, screen, data, selectedidx, distance) As Integer
        newidx = selectedidx + distance
        count = data.items.Count()
        If newidx >= count Then newidx = newidx - count
        If newidx < 0 Then newidx = count + newidx
        player.SetNext(newidx)
        player.Play()

        ' Blank the screen until the next track starts
        ' We also remove the buttons, since they'll be added
        ' back again once the next track is ready.
        screen.SetContent({})
        screen.ClearButtons()
        screen.Show()

        return newidx
    End Function

    While true
        msg = wait(0, port)
        msgtype = type(msg)

        If msgtype = "roSpringboardScreenEvent" Then
           If msg.isScreenClosed() Then
               Exit While
           Else If msg.isButtonPressed() Then
               buttonidx = msg.GetIndex()
               If buttonidx = 1001 Then
                   player.Pause()
                   RunAudioPlayerPauseDialog(port)
                   player.Resume()
               Else If buttonidx = 1002 Then
                   selectedidx = skip(player, screen, data, selectedidx, 1)
               End If
           Else If msg.isRemoteKeyPressed() Then
                key = msg.GetIndex()
                If key = 5 Then
                    ' Right
                    selectedidx = skip(player, screen, data, selectedidx, 1)
                Else if key = 4 Then
                    ' Left
                    selectedidx = skip(player, screen, data, selectedidx, -1)
                Else
                    print "Pressed unhandled key " + Str(key)
                End If
           End If
        Else If msgtype = "roAudioPlayerEvent" Then
           If msg.IsStatusMessage() Then
              print "Player Status: " + msg.GetMessage()
           Else If msg.isListitemSelected() Then
              selectedidx = msg.GetIndex()
              print "Starting to play item " + Str(selectedidx)
              item = data.items[selectedidx]
              screen.SetContent(item)
              screen.AddButton(1001, "Pause")
              screen.AddButton(1002, "Skip")
              screen.Show()

              ' Prefetch the poster for the next track so that
              ' the screen updates instantly when we complete
              ' this track.
              If selectedidx < data.items.Count() - 1 Then
                  nexttrack = data.items[selectedidx + 1]
                  sdposter = nexttrack.sdposterurl
                  hdposter = nexttrack.hdposterurl
                  If sdposter = invalid Then sdposter = ""
                  If hdposter = invalid Then hdposter = ""
                  If sdposter <> "" or hdposter <> "" Then
                      screen.PrefetchPoster(sdposter, hdposter)
                  End If
              End If

           Else If msg.IsRequestFailed() Then
              print "Audio request failed. Skipping to next track."
              selectedidx = skip(player, screen, data, selectedidx, 1)
           Else
              print "Unhandled audio player event " + Str(msg.GetType())
           End If
        End If
    End While

End Sub

Sub RunAudioPlayerPauseDialog(port)

    print "Entering pause dialog"

    ' Use a separate message port for this so we don't
    ' disturb the events on the player's own port.
    pauseport = CreateObject("roMessagePort")

    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(pauseport)
    dialog.SetTitle("Paused")
    dialog.AddButton(1, "Resume")
    dialog.Show()

    While true
        msg = wait(0, pauseport)
        msgtype = type(msg)

        If msgtype = "roMessageDialogEvent"
            If msg.IsScreenClosed() Then
                Exit While
            Else If msg.IsButtonPressed() Then
                Exit While
            End If
        End If
    End While

    print "Leaving pause dialog"

End Sub
