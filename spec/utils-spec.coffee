path = require "path"
utils = require "../lib/utils"

describe "utils", ->

# ==================================================
# General Utils
#

  describe ".slugize", ->
    it "slugize string", ->
      fixture = "hello world!"
      expect(utils.slugize(fixture)).toEqual("hello-world")
      fixture = "hello-world"
      expect(utils.slugize(fixture)).toEqual("hello-world")
      fixture = " hello     World"
      expect(utils.slugize(fixture)).toEqual("hello-world")

    it "slugize chinese", ->
      fixture = "中文也可以"
      expect(utils.slugize(fixture)).toEqual("中文也可以")
      fixture = "中文：也可以"
      expect(utils.slugize(fixture)).toEqual("中文：也可以")
      fixture = " 「中文」  『也可以』"
      expect(utils.slugize(fixture)).toEqual("「中文」-『也可以』")

    it "slugize empty string", ->
      expect(utils.slugize(undefined)).toEqual("")
      expect(utils.slugize("")).toEqual("")

  describe ".getPackagePath", ->
    it "get the package path", ->
      root = atom.packages.resolvePackagePath("markdown-writer")
      expect(utils.getPackagePath()).toEqual(root)

    it "get the path to package file", ->
      root = atom.packages.resolvePackagePath("markdown-writer")
      cheatsheetPath = path.join(root, "CHEATSHEET.md")
      expect(utils.getPackagePath("CHEATSHEET.md")).toEqual(cheatsheetPath)

# ==================================================
# Template
#

  describe ".template", ->
    it "generate template", ->
      fixture = "<a href=''>hello <title>! <from></a>"
      expect(utils.template(fixture, title: "world", from: "markdown-writer"))
        .toEqual("<a href=''>hello world! markdown-writer</a>")

    it "generate template with data missing", ->
      fixture = "<a href='<url>' title='<title>'><img></a>"
      expect(utils.template(fixture, url: "//", title: ''))
        .toEqual("<a href='//' title=''><img></a>")

  describe ".untemplate", ->
    it "generate untemplate for normal text", ->
      fn = utils.untemplate("text")
      expect(fn("text")).toEqual(_: "text")
      expect(fn("abc")).toEqual(undefined)

    it "generate untemplate for template", ->
      fn = utils.untemplate("{year}-{month}")
      expect(fn("2016-11-12")).toEqual(undefined)
      expect(fn("2016-01")).toEqual(_: "2016-01", year: "2016", month: "01")

    it "generate untemplate for complex template", ->
      fn = utils.untemplate("{year}-{month}-{day} {hour}:{minute}")
      expect(fn("2016-11-12")).toEqual(undefined)
      expect(fn("2016-01-03 12:19")).toEqual(
        _: "2016-01-03 12:19", year: "2016", month: "01",
        day: "03", hour: "12", minute: "19")

# ==================================================
# Date and Time
#

  describe ".parseDate", ->
    it "parse date dashed string", ->
      date = utils.getDate()
      parseDate = utils.parseDate(date)
      expect(parseDate).toEqual(date)

# ==================================================
# Image HTML Tag
#

  it "check is valid html image tag", ->
    fixture = """
    <img alt="alt" src="src.png" class="aligncenter" height="304" width="520">
    """
    expect(utils.isImageTag(fixture)).toBe(true)

  it "check parse valid html image tag", ->
    fixture = """
    <img alt="alt" src="src.png" class="aligncenter" height="304" width="520">
    """
    expect(utils.parseImageTag(fixture)).toEqual
      alt: "alt", src: "src.png",
      class: "aligncenter", height: "304", width: "520"

  it "check parse valid html image tag with title", ->
    fixture = """
    <img title="" src="src.png" class="aligncenter" height="304" width="520" />
    """
    expect(utils.parseImageTag(fixture)).toEqual
      title: "", src: "src.png",
      class: "aligncenter", height: "304", width: "520"

# ==================================================
# Image
#

  it "check is valid image", ->
    fixture = "![text](url)"
    expect(utils.isImage(fixture)).toBe(true)
    fixture = "[text](url)"
    expect(utils.isImage(fixture)).toBe(false)

  it "parse valid image", ->
    fixture = "![text](url)"
    expect(utils.parseImage(fixture)).toEqual
      alt: "text", src: "url", title: ""

  it "check is valid image file", ->
    fixture = "fixtures/abc.jpg"
    expect(utils.isImageFile(fixture)).toBe(true)
    fixture = "fixtures/abc.txt"
    expect(utils.isImageFile(fixture)).toBe(false)

# ==================================================
# Link
#

  describe ".isInlineLink", ->
    it "check is text invalid inline link", ->
      fixture = "![text](url)"
      expect(utils.isInlineLink(fixture)).toBe(false)
      fixture = "[text]()"
      expect(utils.isInlineLink(fixture)).toBe(false)
      fixture = "[text][]"
      expect(utils.isInlineLink(fixture)).toBe(false)

    it "check is text valid inline link", ->
      fixture = "[text](url)"
      expect(utils.isInlineLink(fixture)).toBe(true)
      fixture = "[text](url title)"
      expect(utils.isInlineLink(fixture)).toBe(true)
      fixture = "[text](url 'title')"
      expect(utils.isInlineLink(fixture)).toBe(true)

  it "parse valid inline link text", ->
    fixture = "[text](url)"
    expect(utils.parseInlineLink(fixture)).toEqual(
      {text: "text", url: "url", title: ""})
    fixture = "[text](url title)"
    expect(utils.parseInlineLink(fixture)).toEqual(
      {text: "text", url: "url", title: "title"})
    fixture = "[text](url 'title')"
    expect(utils.parseInlineLink(fixture)).toEqual(
      {text: "text", url: "url", title: "title"})

  describe ".isReferenceLink", ->
    it "check is text invalid reference link", ->
      fixture = "![text](url)"
      expect(utils.isReferenceLink(fixture)).toBe(false)
      fixture = "[text](has)"
      expect(utils.isReferenceLink(fixture)).toBe(false)

    it "check is text valid reference link", ->
      fixture = "[text][]"
      expect(utils.isReferenceLink(fixture)).toBe(true)

    it "check is text valid reference link with id", ->
      fixture = "[text][id with space]"
      expect(utils.isReferenceLink(fixture)).toBe(true)

  describe ".parseReferenceLink", ->
    editor = null

    beforeEach ->
      waitsForPromise -> atom.workspace.open("empty.markdown")
      runs ->
        editor = atom.workspace.getActiveTextEditor()
        editor.setText """
        Transform your plain [text][] into static websites and blogs.

        [text]: http://www.jekyll.com
        [id]: http://jekyll.com "Jekyll Website"

        Markdown (or Textile), Liquid, HTML & CSS go in [Jekyll][id].
        """

    it "parse valid reference link text without id", ->
      fixture = "[text][]"
      expect(utils.parseReferenceLink(fixture, editor)).toEqual
        id: "text", text: "text", url: "http://www.jekyll.com", title: ""
        definitionRange: {start: {row: 2, column: 0}, end: {row: 2, column: 29}}

    it "parse valid reference link text with id", ->
      fixture = "[Jekyll][id]"
      expect(utils.parseReferenceLink(fixture, editor)).toEqual
        id: "id", text: "Jekyll", url: "http://jekyll.com", title: "Jekyll Website"
        definitionRange: {start: {row: 3, column: 0}, end: {row: 3, column: 40}}

  describe ".isReferenceDefinition", ->
    it "check is text invalid reference definition", ->
      fixture = "[text] http"
      expect(utils.isReferenceDefinition(fixture)).toBe(false)

    it "check is text valid reference definition", ->
      fixture = "[text text]: http"
      expect(utils.isReferenceDefinition(fixture)).toBe(true)

    it "check is text valid reference definition with title", ->
      fixture = "  [text]: http 'title not in double quote'"
      expect(utils.isReferenceDefinition(fixture)).toBe(true)

  describe ".parseReferenceLink", ->
    editor = null

    beforeEach ->
      waitsForPromise -> atom.workspace.open("empty.markdown")
      runs ->
        editor = atom.workspace.getActiveTextEditor()
        editor.setText """
        Transform your plain [text][] into static websites and blogs.

        [text]: http://www.jekyll.com
        [id]: http://jekyll.com "Jekyll Website"

        Markdown (or Textile), Liquid, HTML & CSS go in [Jekyll][id].
        """

    it "parse valid reference definition text without id", ->
      fixture = "[text]: http://www.jekyll.com"
      expect(utils.parseReferenceDefinition(fixture, editor)).toEqual
        id: "text", text: "text", url: "http://www.jekyll.com", title: ""
        linkRange: {start: {row: 0, column: 21}, end: {row: 0, column: 29}}

    it "parse valid reference definition text with id", ->
      fixture = "[id]: http://jekyll.com \"Jekyll Website\""
      expect(utils.parseReferenceDefinition(fixture, editor)).toEqual
        id: "id", text: "Jekyll", url: "http://jekyll.com", title: "Jekyll Website"
        linkRange: {start: {row: 5, column: 48}, end: {row: 5, column: 60}}

# ==================================================
# Table
#

  describe ".isTableSeparator", ->
    it "check is table separator", ->
      fixture = "----|"
      expect(utils.isTableSeparator(fixture)).toBe(false)

      fixture = "|--|"
      expect(utils.isTableSeparator(fixture)).toBe(true)
      fixture = "--|--"
      expect(utils.isTableSeparator(fixture)).toBe(true)
      fixture = "---- |------ | ---"
      expect(utils.isTableSeparator(fixture)).toBe(true)

    it "check is table separator with extra pipes", ->
      fixture = "|-----"
      expect(utils.isTableSeparator(fixture)).toBe(false)

      fixture = "|--|--"
      expect(utils.isTableSeparator(fixture)).toBe(true)
      fixture = "|---- |------ | ---|"
      expect(utils.isTableSeparator(fixture)).toBe(true)

    it "check is table separator with format", ->
      fixture = ":--  |::---"
      expect(utils.isTableSeparator(fixture)).toBe(false)

      fixture = "|:---: |"
      expect(utils.isTableSeparator(fixture)).toBe(true)
      fixture = ":--|--:"
      expect(utils.isTableSeparator(fixture)).toBe(true)
      fixture = "|:---: |:----- | --: |"
      expect(utils.isTableSeparator(fixture)).toBe(true)

  describe ".parseTableSeparator", ->
    it "parse table separator", ->
      fixture = "|----|"
      expect(utils.parseTableSeparator(fixture)).toEqual({
        separator: true
        extraPipes: true
        alignments: ["empty"]
        columns: ["----"]
        columnWidths: [4]})

      fixture = "--|--"
      expect(utils.parseTableSeparator(fixture)).toEqual({
        separator: true
        extraPipes: false
        alignments: ["empty", "empty"]
        columns: ["--", "--"]
        columnWidths: [2, 2]})

      fixture = "---- |------ | ---"
      expect(utils.parseTableSeparator(fixture)).toEqual({
        separator: true
        extraPipes: false
        alignments: ["empty", "empty", "empty"]
        columns: ["----", "------", "---"]
        columnWidths: [4, 6, 3]})

    it "parse table separator with extra pipes", ->
      fixture = "|--|--"
      expect(utils.parseTableSeparator(fixture)).toEqual({
        separator: true
        extraPipes: true
        alignments: ["empty", "empty"]
        columns: ["--", "--"]
        columnWidths: [2, 2]})

      fixture = "|---- |------ | ---|"
      expect(utils.parseTableSeparator(fixture)).toEqual({
        separator: true
        extraPipes: true
        alignments: ["empty", "empty", "empty"]
        columns: ["----", "------", "---"]
        columnWidths: [4, 6, 3]})

    it "parse table separator with format", ->
      fixture = ":-|-:|::"
      expect(utils.parseTableSeparator(fixture)).toEqual({
        separator: true
        extraPipes: false
        alignments: ["left", "right", "center"]
        columns: [":-", "-:", "::"]
        columnWidths: [2, 2, 2]})

      fixture = ":--|--:"
      expect(utils.parseTableSeparator(fixture)).toEqual({
        separator: true
        extraPipes: false
        alignments: ["left", "right"]
        columns: [":--", "--:"]
        columnWidths: [3, 3]})

      fixture = "|:---: |:----- | --: |"
      expect(utils.parseTableSeparator(fixture)).toEqual({
        separator: true
        extraPipes: true
        alignments: ["center", "left", "right"]
        columns: [":---:", ":-----", "--:"]
        columnWidths: [5, 6, 3]})

  describe ".isTableRow", ->
    it "check table separator is a table row", ->
      fixture = ":--  |:---"
      expect(utils.isTableRow(fixture)).toBe(true)

    it "check is table row", ->
      fixture = "| empty content |"
      expect(utils.isTableRow(fixture)).toBe(true)
      fixture = "abc|feg"
      expect(utils.isTableRow(fixture)).toBe(true)
      fixture = "|   abc |efg | |"
      expect(utils.isTableRow(fixture)).toBe(true)

  describe ".parseTableRow", ->
    it "parse table separator by table row ", ->
      fixture = "|:---: |:----- | --: |"
      expect(utils.parseTableRow(fixture)).toEqual({
        separator: true
        extraPipes: true
        alignments: ["center", "left", "right"]
        columns: [":---:", ":-----", "--:"]
        columnWidths: [5, 6, 3]})

    it "parse table row ", ->
      fixture = "| 中文 |"
      expect(utils.parseTableRow(fixture)).toEqual({
        separator: false
        extraPipes: true
        columns: ["中文"]
        columnWidths: [4]})

      fixture = "abc|feg"
      expect(utils.parseTableRow(fixture)).toEqual({
        separator: false
        extraPipes: false
        columns: ["abc", "feg"]
        columnWidths: [3, 3]})

      fixture = "|   abc |efg | |"
      expect(utils.parseTableRow(fixture)).toEqual({
        separator: false
        extraPipes: true
        columns: ["abc", "efg", ""]
        columnWidths: [3, 3, 0]})

  it "create table separator", ->
    row = utils.createTableSeparator(
      numOfColumns: 3, extraPipes: false, columnWidth: 1, alignment: "empty")
    expect(row).toEqual("--|---|--")

    row = utils.createTableSeparator(
      numOfColumns: 2, extraPipes: true, columnWidth: 1, alignment: "empty")
    expect(row).toEqual("|---|---|")

    row = utils.createTableSeparator(
      numOfColumns: 1, extraPipes: true, columnWidth: 1, alignment: "left")
    expect(row).toEqual("|:--|")

    row = utils.createTableSeparator(
      numOfColumns: 3, extraPipes: true, columnWidths: [2, 3, 3],
      alignment: "left")
    expect(row).toEqual("|:---|:----|:----|")

    row = utils.createTableSeparator(
      numOfColumns: 4, extraPipes: false, columnWidth: 3,
      alignment: "left", alignments: ["empty", "right", "center"])
    expect(row).toEqual("----|----:|:---:|:---")

  it "create empty table row", ->
    row = utils.createTableRow([],
      numOfColumns: 3, columnWidth: 1, alignment: "empty")
    expect(row).toEqual("  |   |  ")

    row = utils.createTableRow([],
      numOfColumns: 3, extraPipes: true, columnWidths: [1, 2, 3],
      alignment: "empty")
    expect(row).toEqual("|   |    |     |")

  it "create table row", ->
    row = utils.createTableRow(["中文", "English"],
      numOfColumns: 2, extraPipes: true, columnWidths: [4, 7])
    expect(row).toEqual("| 中文 | English |")

    row = utils.createTableRow(["中文", "English"],
      numOfColumns: 2, columnWidths: [8, 10], alignments: ["right", "center"])
    expect(row).toEqual("    中文 |  English  ")

  it "create an empty table", ->
    rows = []

    options =
      numOfColumns: 3, columnWidths: [4, 1, 4],
      alignments: ["left", "center", "right"]

    rows.push(utils.createTableRow([], options))
    rows.push(utils.createTableSeparator(options))
    rows.push(utils.createTableRow([], options))

    expect(rows).toEqual([
      "     |   |     "
      ":----|:-:|----:"
      "     |   |     "
    ])

  it "create an empty table with extra pipes", ->
    rows = []

    options =
      numOfColumns: 3, extraPipes: true,
      columnWidth: 1, alignment: "empty"

    rows.push(utils.createTableRow([], options))
    rows.push(utils.createTableSeparator(options))
    rows.push(utils.createTableRow([], options))

    expect(rows).toEqual([
      "|   |   |   |"
      "|---|---|---|"
      "|   |   |   |"
    ])

# ==================================================
# URL
#

  it "check is url", ->
    fixture = "https://github.com/zhuochun/md-writer"
    expect(utils.isUrl(fixture)).toBe(true)
    fixture = "/Users/zhuochun/md-writer"
    expect(utils.isUrl(fixture)).toBe(false)

# ==================================================
# Atom TextEditor
#
