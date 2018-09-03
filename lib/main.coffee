{CompositeDisposable} = require 'atom'

Bookmarks = null
ReactBookmarks = null
BookmarksView = require './bookmarks-view'
editorsBookmarks = null
disposables = null

module.exports =




  activate: (bookmarksByEditorId) ->

    editorsBookmarks = []
    watchedEditors = new WeakSet()
    bookmarksView = null
    disposables = new CompositeDisposable

    navigate = (offset,editor) ->
      cur = editorsBookmarks.findIndex((x) -> x.editor == editor)
      toSearch = editorsBookmarks.slice(cur+1).concat(editorsBookmarks.slice(0,cur))
      if offset < 0
        toSearch = toSearch.reverse()

      next = toSearch.find((x) -> x.markerLayer.getMarkers().length)

      if next
        markers = next.markerLayer.getMarkers()
        marker = markers[if offset > 0 then 0 else (markers.length-1)]
        nexteditor = next.editor
        nexteditor.setSelectedBufferRange(marker.getBufferRange(), {autoscroll: true})
        atom.workspace.paneForItem(nexteditor).activate()
        atom.workspace.paneForItem(nexteditor).activateItem(nexteditor)



    atom.commands.add 'atom-workspace',
      'bookmarks:view-all', ->
        bookmarksView ?= new BookmarksView(editorsBookmarks)
        bookmarksView.show()

    atom.workspace.observeTextEditors (textEditor) ->
      return if watchedEditors.has(textEditor)

      Bookmarks ?= require './bookmarks'
      if state = bookmarksByEditorId[textEditor.id]
        bookmarks = Bookmarks.deserialize(textEditor, state, navigate)
      else
        bookmarks = new Bookmarks(textEditor,state, navigate)
      editorsBookmarks.push(bookmarks)
      watchedEditors.add(textEditor)
      disposables.add textEditor.onDidDestroy ->
        index = editorsBookmarks.indexOf(bookmarks)
        editorsBookmarks.splice(index, 1) if index isnt -1
        bookmarks.destroy()
        watchedEditors.delete(textEditor)

  deactivate: ->
    bookmarksView?.destroy()
    bookmarks.deactivate() for bookmarks in editorsBookmarks
    disposables.dispose()

  serialize: ->
    bookmarksByEditorId = {}
    for bookmarks in editorsBookmarks
      bookmarksByEditorId[bookmarks.editor.id] = bookmarks.serialize()
    bookmarksByEditorId
