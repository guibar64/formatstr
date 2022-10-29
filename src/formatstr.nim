# Edited from
#            
#           Nim's Runtime Library
#        (c) Copyright 2017 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#  
#  (c) Copyright 2022 G. Bareigts
#

import strformat, parseutils, macros

export formatValue


type
  FmtHelper {.shallow.} = object
    s: string
    pos, i: int
    notNumber: bool
    argPos, argLen: int
    spec: string
    result: string
  SyntaxError* = object of ValueError


proc initFmtHelper(s: string, argLen: int): FmtHelper =
  result = FmtHelper(s: s,
                     i: 0,
                     notNumber: false,
                     pos: 0,
                     argPos: -1,
                     argLen: argLen,
                     spec: newStringOfCap(10),
                     result: newStringOfCap(s.len)
    )

proc getSpecifier(v: string, pos: int, spec: var string) =
  var ix = pos
  if ix >= v.len-1:
    spec = ""
    return
  for i in 0..<v.len:
    if v[i] == ':':
      ix = i+1
      break
  setLen(spec, v.len-ix)
  for i in 0..(v.len-1-ix):
    spec[i] = v[i+ix]

proc nextFmt*(s: var FmtHelper): bool =
  result = false
  const speChars = {'\\', '{', '}'}
  var fs: string
  var i = s.pos
  while i < s.s.len:
    case s.s[i]
    of '\\':
      case s.s[i+1]
      of '{', '}':
        s.result.add s.s[i+1]
        i += 2
      else: discard
    of '{':
      var pos: int
      let p = parseUntil(s.s, fs, '}', i+1)
      let pt = parseInt(fs, pos)
      if pt <= 0:
        if s.notNumber: raise newException(SyntaxError, "Cannot use unumbered format argument after first numbered ones")
        pos = s.i
        inc(s.i)
      else:
        dec(pos)
        s.notNumber = true
      if pos < 0 or pos >= s.argLen:
        raise newException(SyntaxError, $pos & ": Incorrect position of argument")
      getSpecifier(fs, pt, s.spec)
      i += p+2
      s.pos = i
      s.argPos = pos
      return true
    of '}':
      raise newException(SyntaxError, fmt"Incorrect format at char {i} on {s}")
    else:
      let p = parseUntil(s.s, fs, speChars, i)
      s.result.add fs
      i += p


template callFormatValue(res, arg, option) {.dirty.} =
  when compiles(formatValue(res, arg, option)):
    formatValue(res, arg, option)
  else:
    formatValue(res, $arg, option)

macro format*(pattern: string, args: varargs[typed]): string =
  ## Format string `pattern` from `args`
  let
    r = ident("r")
    pos = nnkDotExpr.newTree(r, ident("argPos"))
    res = nnkDotExpr.newTree(r, ident("result"))
    spec = nnkDotExpr.newTree(r, ident("spec"))
  let
    caseBrs = newTree(nnkCaseStmt, pos)
  for i in 0..<args.len:
    caseBrs.add newTree(nnkOfBranch,
                        newLit(i), getAst(callFormatValue(res, args[i], spec)))
  caseBrs.add newTree(nnkElse, newTree(nnkDiscardStmt, newEmptyNode()))
  let aLen = newLit(args.len)
  let fmtEval = quote do:
    var `r` = initFmtHelper(`pattern`, `aLen`)
    while `r`.nextFmt:
      `caseBrs`
    `r`.result
  result = newBlockStmt(newStmtList(fmtEval))
