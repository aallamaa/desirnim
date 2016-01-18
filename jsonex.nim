import json, strutils
import macros

var data = parseFile("commands.json")

echo len(data)

var txt = ""
for cmdname,cmddict in data:
  txt &= cmdname & "|" & cmddict["summary"].str & "\n"
writeFile("commands.csv", txt)
  
