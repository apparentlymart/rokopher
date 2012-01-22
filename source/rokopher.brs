
Sub RunPosterScreen(liststyle, data, port)

    print "Preparing to show a poster screen with style " + liststyle

    screen = CreateObject("roPosterScreen")

    If data.title <> invalid Then
        If data.parenttitle <> invalid Then
           screen.SetBreadcrumbText(data.parenttitle, data.title)
        Else
           screen.SetBreadcrumbText(data.title, "")
        End If
    End If

    If data.imagestyle <> invalid Then screen.SetListDisplayMode(data.imagestyle)

    screen.SetListStyle(liststyle)

    If data.categories.Count() > 1 Or (data.categories.Count() = 1 And data.categories[0].title <> invalid) Then
        listnames = []
        For Each category In data.categories
            listnames.Push(category.title)
        End For
        screen.SetListNames(listnames)
    End If

    showitems = Function (screen, items)
        screen.SetContentList(items)
    End Function

    categoryindex = 0

    If data.categories.Count() > 0 Then
        print "Showing the items from the selected category"
        showitems(screen, data.categories[categoryindex].items)
    Else
        print "There are no categories, so not showing any items"
    End If

    screen.SetMessagePort(port)
    screen.Show()

    While true
        msg = wait(0, port)
        msgtype = type(msg)

        If msgtype = "roPosterScreenEvent" Then
            If msg.IsListFocused() Then
                categoryindex = msg.GetIndex()
                print "Selected category" + Str(categoryindex)
                showitems(screen, data.categories[categoryindex].items)
            End If
        End If
    End While

End Sub

Sub HandleCategorizedList(elem, port)

    print "Preparing to show a categorized list"

    attr = elem.GetAttributes()

    stylename = attr.style
    If stylename = invalid Then
        stylename = ""
    End If

    styles = {}
    styles["tree:arced-portrait"] = [ RunPosterScreen, "arced-portrait" ]
    styles["tree:arced-landscape"] = [ RunPosterScreen, "arced-landscape" ]
    styles["tree:arced-16x9"] = [ RunPosterScreen, "arced-16x9" ]
    styles["tree:arced-square"] = [ RunPosterScreen, "arced-square" ]
    styles["tree:flat-category"] = [ RunPosterScreen, "flat-category" ]
    styles["tree:flat-episodic"] = [ RunPosterScreen, "flat-episodic" ]
    styles["tree:flat-16x9"] = [ RunPosterScreen, "flat-16x9" ]
    styles["tree:flat-episodic-16x9"] = [ RunPosterScreen, "flat-episodic-16x9" ]
    stylehandler = styles.Lookup(stylename)
    If stylehandler = invalid then stylehandler = styles.Lookup("tree:arced-portrait")
    stylehandlerfunc = stylehandler[0]
    stylehandlertype = stylehandler[1]

    data = {}
    data.title = attr.title
    data.parenttitle = attr.parenttitle
    data.imagestyle = attr.imagestyle
    data.categories = []

    categoryelems = elem.GetNamedElements("category")
    For Each categoryelem In categoryelems
        category = {}
        category.title = categoryelem.GetAttributes().title
        category.items = []
        itemelems = categoryelem.GetNamedElements("item")
        For Each itemelem In itemelems
            item = ContentMetadataFromXML(itemelem)
            category.items.Push(item)
        End For
        data.categories.Push(category)
    End For

    stylehandlerfunc(stylehandlertype, data, port)

End Sub

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
    ' FIXME: Do this asynchronously with a loading screen
    xml = ua.GetToString()
    print "Got XML " + xml

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
        categorizedlist: HandleCategorizedList
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

Sub ContentMetadataFromXML(elem) As Dynamic

    attr = elem.GetAttributes()

    ret = {}

    ret.ContentType = attr.contenttype
    ret.Title = attr.title
    ret.TitleSeason = attr.seasontitle
    ret.Description = attr.description
    ret.ShortDescriptionLine1 = attr.shortdescription1
    ret.ShortDescriptionLine2 = attr.shortdescription2
    ret.HDPosterUrl = attr.hdpostersrc

    'If ret.ShortDescriptionLine1 == invalid Then
    '    ret.ShortDescriptionLine1 = ret.Title
    'End If

    Return ret

End Sub
