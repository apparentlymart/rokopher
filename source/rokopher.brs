
Sub Main()

    port = CreateObject("roMessagePort")
    screenFacade = CreateObject("roPosterScreen")
    screenFacade.show()

    Navigate("http://192.168.4.8:8084/index.xml", port)

    screenFacade.ShowMessage("")
    sleep(25)
End Sub

Sub Navigate(url, port)
    print "Navigating to " + url
    ua = CreateObject("roUrlTransfer")
    elem = CreateObject("roXMLElement")
    ua.SetUrl(url)
    ua.SetPort(port)

    dialog = CreateObject("roOneLineDialog")
    dialog.SetMessagePort(port)
    dialog.SetTitle("Retrieving...")
    dialog.ShowBusyAnimation()
    dialog.Show()

    sent = ua.AsyncGetToString()
    If not sent Then
        ' FIXME: Fail in the UI
        print "Failed to send HTTP request"
        return
    End If

    xml = invalid

    While true
        msg = wait(0, port)
        msgtype = type(msg)

        If msgtype = "roUrlEvent" Then
            status = msg.GetResponseCode()
            If status = 200 Then
                xml = msg.GetString()
                dialog.Close()
            Else
                ' TODO: Handle errors with a reasonable error in the UI
                print "Response code is " + Str(status) + " " + msg.GetFailureReason()
            End If
        Else If msgtype = "roOneLineDialogEvent"
            If msg.IsScreenClosed() Then
                Exit While
            End If
        End If
    End While

    If elem.Parse(xml) Then
        RunScreenFromXML(elem, port)
    Else
        ' FIXME: Display a reasonable error in the UI
        print "XML parse error"
    End If
End Sub

Sub RunScreenFromXML(elem, port)

    screentype = elem.GetName()
    print "Running a screen of type " + screentype

    screentypes = {
        categorizedlist: HandleCategorizedList,
        itemdetail: HandleItemDetail,
        imageplaylist: HandleImagePlaylist
    }

    handler = screentypes.Lookup(screentype)

    If handler <> invalid Then
        print "Running " + screentype + " handler"
        handler(elem, port)
    Else
        ' FIXME: Display a reasonable error in the UI
        print "No handler for screen type " + screentype
    End If

End Sub

Sub RestrictedContentMetadataArrayFromXMLList(elems, allowednames) As Dynamic

    print "Searching for items in XML list"

    allowed = {}
    For Each name in allowednames
        allowed[name] = true
    End For

    ret = []
    For Each elem in elems
        elemname = elem.GetName()
        print "Found " + elemname + " element"
        If allowed[elemname] Then
            ret.Push(ContentMetadataFromXML(elem))
        Else
            print "Skipping " + elemname + " element that can't represent an item here"
        End If
    End For
    return ret

End Sub

Sub ContentMetadataArrayFromXMLList(elems) As Dynamic
    Return RestrictedContentMetadataArrayFromXMLList(elems, [
        "movie",
        "episode", "season", "series",
        "song", "songalbum",
        "photo", "photoalbum",
        "genericitem", "genericvideo", "livevideo", "genericaudio", "genericimage"
    ])
End Sub

Sub ContentMetadataFromXML(elem) As Dynamic

    attr = elem.GetAttributes()
    elemtype = elem.GetName()

    ret = {}

    ' Attributes common to all types
    ret.Title = attr.title
    ret.HDPosterUrl = attr.hdposterurl
    ret.SDPosterUrl = attr.sdposterurl
    ret.Description = attr.description
    ret.ShortDescriptionLine1 = attr.shortdescription1
    ret.ShortDescriptionLine2 = attr.shortdescription2

    ' Actions
    ' These are not actually part of the Roku content metadata
    ' definition, but are rather an extension used by rokopher
    ' to represent the per-item action target information.
    ret.rokopherActions = {}
    For Each actionelem In elem.GetNamedElements("action")
        actionattr = actionelem.GetAttributes()
        actionid = actionattr.id
        If actionid <> invalid Then
            action = {
                url: actionattr.url,
                method: actionattr.method
            }
            If action.method = invalid Then action.method = "GET"
            ret.rokopherActions[actionid] = action
        Else
            print "Ignoring action with no id attribute"
        End If
    End For

    ' Type-specific attributes
    If elemtype = "movie" Then
        ret.ContentType = "movie"
    Else If elemtype = "episode" Then
        ret.ContentType = "episode"
        ret.TitleSeason = attr.seasontitle
    Else If elemtype = "season" Then
        ret.ContentType = "season"
        ret.TitleSeason = attr.seriestitle
    Else If elemtype = "series" Then
        ret.ContentType = "series"
    Else If elemtype = "song"
        ret.Album = attr.albumname
        ret.Artist = attr.artistname
    End If

    ' Type class attributes
    If elemtype = "movie" or elemtype = "episode" or elemtype = "genericvideo" Then
        ' TODO: Decode "stream" child elements, BIF URL, subtitles URL...
    End If
    If elemtype = "livevideo" Then
        ' TODO: Decode "stream" child elements in the special way that
        ' is different for HTTP Live Streaming.
    End If

    If elemtype = "song" or elemtype = "genericaudio" Then
        ret.ContentType = "audio"
    End If

    If elemtype = "photo" or elemtype = "genericimage" Then
        ret.Url = attr.fullsrc
    End If

    ' If the document doesn't provide specific values for the
    ' short description line 1 then substitute the title.
    If ret.ShortDescriptionLine1 = invalid Then
        ret.ShortDescriptionLine1 = ret.Title
    End If

    Return ret

End Sub
