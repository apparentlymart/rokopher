
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
    styles["grid:flat-movie"] = [ RunGridScreen, "flat-movie" ]
    styles["grid:flat-portrait"] = [ RunGridScreen, "flat-portrait" ]
    styles["grid:flat-landscape"] = [ RunGridScreen, "flat-landscape" ]
    styles["grid:flat-square"] = [ RunGridScreen, "flat-square" ]
    styles["grid:flat-16x9"] = [ RunGridScreen, "flat-16x9" ]
    stylehandler = styles.Lookup(stylename)
    If stylehandler = invalid then stylehandler = styles.Lookup("tree:arced-portrait")
    stylehandlerfunc = stylehandler[0]
    stylehandlertype = stylehandler[1]

    data = {}
    data.title = attr.title
    data.parenttitle = attr.parenttitle
    data.imagestyle = attr.imagestyle
    data.categories = []
    data.selectactions = []

    categoryelems = elem.GetNamedElements("category")
    For Each categoryelem In categoryelems
        category = {}
        category.title = categoryelem.GetAttributes().title
        category.items = ContentMetadataArrayFromXMLList(categoryelem.GetChildElements())
        data.categories.Push(category)
    End For

    selectactionelems = elem.GetNamedElements("selectaction")
    For Each selectactionelem In selectactionelems
        actionid = selectactionelem.GetAttributes().id
        data.selectactions.Push(actionid)
    End For

    stylehandlerfunc(stylehandlertype, data, port)

End Sub

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
            Else if msg.IsListItemSelected() Then
                itemindex = msg.GetIndex()
                selecteditem = data.categories[categoryindex].items[itemindex]
                For Each selectactionname In data.selectactions
                    selectaction = selecteditem.rokopherActions[selectactionname]
                    If selectaction <> invalid Then
                        print "Activating the " + selectactionname + " action"
                        ' TODO: Support method=POST
                        Navigate(selectaction.url, port)
                    End If
                End For
            Else If msg.isScreenClosed() Then
               Exit While
            End If
        End If
    End While

End Sub

Sub RunGridScreen(gridstyle, data, port)

    print "Preparing to show a grid screen with style " + gridstyle

    screen = CreateObject("roGridScreen")

    If data.title <> invalid Then
        If data.parenttitle <> invalid Then
           screen.SetBreadcrumbText(data.parenttitle, data.title)
        Else
           screen.SetBreadcrumbText(data.title, "")
        End If
    End If

    If data.imagestyle <> invalid Then screen.SetDisplayMode(data.imagestyle)

    screen.SetGridStyle(gridstyle)

    categorycount = data.categories.Count()
    screen.SetupLists(categorycount)
    listnames = []
    For categoryidx = 0 to categorycount - 1
        category = data.categories[categoryidx]
        listnames.Push(category.title)
        screen.SetContentList(categoryidx, category.items)
    End For
    screen.SetListNames(listnames)

    screen.SetMessagePort(port)
    screen.Show()

    While true
        msg = wait(0, port)
        msgtype = type(msg)

        If msgtype = "roGridScreenEvent" Then

            If msg.isListItemSelected() Then
                categoryindex = msg.GetIndex()
                itemindex = msg.GetData()
                selecteditem = data.categories[categoryindex].items[itemindex]
                For Each selectactionname In data.selectactions
                    selectaction = selecteditem.rokopherActions[selectactionname]
                    If selectaction <> invalid Then
                        print "Activating the " + selectactionname + " action"
                        ' TODO: Support method=POST
                        Navigate(selectaction.url, port)
                    End If
                End For
            End if
        End If
    End While

End Sub

