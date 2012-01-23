
Sub HandleTextView(elem, port)

    print "Preparing to show a text view"

    attr = elem.GetAttributes()

    data = {}
    data.imagestyle = attr.imagestyle
    data.title = attr.title
    If data.title = invalid Then data.title = ""

    data.bodyitems = []
    For Each blockelem In elem.GetChildElements()
        blockelemname = blockelem.GetName()
        If blockelemname = "head" Then
            data.bodyitems.Push({
                kind: "head",
                text: blockelem.GetText()
            })
        Else If blockelemname = "p" Then
            data.bodyitems.Push({
                kind: "para",
                text: blockelem.GetText()
            })
        Else If blockelemname = "image" Then
            blockattr = blockelem.GetAttributes()
            imagestyle = blockattr.imagestyle
            If imagestyle = invalid Then imagestyle = data.imagestyle
            If imagestyle = invalid Then imagestyle = "scale-to-fill"
            data.bodyitems.Push({
                kind: "image",
                url: blockattr.url,
                imagestyle: imagestyle,
            })
        End If
    End For

    RunParagraphScreen(data, port)

End Sub

Sub HandleError(error, port)

    data = {}
    data.title = error.title
    data.bodyitems = []
    If data.title = invalid Then data.title = "Error"

    print "Handling error titled " + data.title

    If error.heading <> invalid Then
        print "Error heading is " + error.heading
        data.bodyitems.Push({
            kind: "head",
            text: error.heading
        })
    End If

    If error.detail <> invalid Then
        data.bodyitems.Push({
            kind: "para",
            text: error.detail
        })
    End If

    If error.url <> invalid Then
        data.bodyitems.Push({
            kind: "para",
            text: error.url
        })
    End If

    RunParagraphScreen(data, port)

End Sub

Sub RunParagraphScreen(data, port)

    print "Preparing to show a paragraph screen for a text view"

    screen = CreateObject("roParagraphScreen")

    screen.SetTitle(data.title)

    For Each item In data.bodyitems
        If item.kind = "head" Then
            print "Adding a heading"
            screen.AddHeaderText(item.text)
        Else If item.kind = "para" Then
            print "Adding a paragraph"
            screen.AddParagraph(item.text)
        Else If item.kind = "image" Then
            print "Adding an image " + item.url
            screen.AddGraphic(item.url, item.imagestyle)
        End If
    End For

    screen.SetMessagePort(port)
    screen.Show()

    While true
        print "waiting for a message"
        msg = wait(0, port)
        msgtype = type(msg)

        If msgtype = "roParagraphScreenEvent" Then
           If msg.isScreenClosed() Then
               Exit While
           End If
        End If
    End While

End Sub
