fs = require 'fs-extra'
converter = require './lib/converter'

langs = fs.readdirSync('./origins')

unless langs
  console.log 'No languages are available'
  process.exit 1

console.log 'Found languages: ' + langs.join(', ')

langs.forEach (lang) -> converter.run(lang)