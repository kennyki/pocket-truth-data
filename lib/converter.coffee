fs = require 'fs-extra'
path = require 'path'
clone = require 'clone'
model = require './model'

processExt = '.csv'
paragraphSuffix = 'RK'

module.exports =

  dataPath: path.join __dirname, '..', 'data'

  run: (lang) ->
    srcFolderPath = path.join __dirname, '..', 'origins', lang
    targetFolderPath = @createTargetFolder lang

    fs.readdirSync(srcFolderPath).forEach (fileName) =>
      @parse srcFolderPath, fileName, targetFolderPath

  createTargetFolder: (lang) ->
    folderPath = path.join @dataPath, lang
    # upsert
    fs.ensureDir folderPath

    return folderPath

  parse: (srcFolderPath, fileName, targetFolderPath) ->
    fileExt = path.extname fileName

    return unless processExt is fileExt

    num = path.basename fileName, fileExt

    json = clone model
    json.number = num

    srcPath = path.join srcFolderPath, fileName

    console.log '====================='
    console.log 'Parsing ' + srcPath

    rawContent = fs.readFileSync srcPath,
      encoding: 'utf-8'
    csvList = @trim rawContent.split /\r?\n/
    csvParagraphs = @toParagraphs csvList

    console.log JSON.stringify csvParagraphs, null, 4

    console.log '====================='

  trim: (csvList) ->
    # TODO: need to trim the front?
    lastIx = csvList.length - 1
    lastRow = csvList[lastIx]

    while lastIx > 0 and !lastRow
      lastRow = csvList[--lastIx]

    # include the last row (that has content)
    return csvList.slice 0, lastIx + 1

  toParagraphs: (csvList) ->
    paragraphs = []
    currentParagraph = []
    verseCount = 0

    # the last paragraph ends with ',R'
    # make it consistent
    csvList[csvList.length - 1] = csvList[csvList.length - 1].replace ',R', ',RK'
    
    csvList.forEach (csv) ->
      # remove 'T,' and ',R' (and all after it - this happens in 004) and convert 'L*' or 'X' to 'L'
      # replace ',RK' with ',_RK' for later processing
      csv = csv.replace('T,', '').replace(',RK', ',_RK').replace(/,R$/, '').replace(/L[0-9]/g, 'L').replace(/X/g, 'L')
      # split by comma
      csv = csv.split ','

      # replace '(verse)' with '' and count verse
      # NOTE: only first paragraph will contain verse numbers
      if /\([0-9]\)/.test csv[0]
        csv[0] = ''
        verseCount++

      currentParagraph.push csv

      csvLastIx = csv.length - 1
      # earlier we have replaced ',RK' with ',_RK' to indicate end of a paragraph
      if csv[csvLastIx] is '_RK'
        # replace it with '' too
        csv[csvLastIx] = ''
        paragraphs.push currentParagraph
        currentParagraph = []

    return {
      paragraphs: paragraphs
      verseCount: verseCount
    }

