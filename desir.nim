import net, os, strutils, parseutils
import macros

type RedisError = object of Exception

type
  RESPKind = enum  # the different RESP (REdis Serialization Protocol) types
    sString,       # simple strings
    cInteger,      # Integer
    bString,       # bulk string
    sArray,        # Array
    # Error is excluded as it is raising an error directly
  RESPObj = object
    case kind: RESPKind  
    of cInteger: intVal: int
    of sString: strVal: string
    of bString: bstrVal: string
    of sArray: rArray: seq[RESPObj]


proc `$`(resp: RESPObj): string = 
  case resp.kind
  of sString:
    if isNil(resp.strVal):
      result = "nil"
    else:
      result = resp.strVal
  of bString: result = resp.bstrVal
  of cInteger: result = $(resp.intVal)
  of sArray:
    result = "[ "
    for v in resp.rArray:
      result &= $(v) & " "
    result &= "]"

type
  Redis* = object
    socket: net.Socket
    connected: bool
    db: int
    host: string
    port: Port
    timeout: int
    password: string
    safe: bool
    safewait: float
    transaction: bool
    subscribed: bool

proc open*(host = "localhost", port = 6379.Port, db = 0, password:string = nil, timeout:int = 0, safe = false): Redis =
  ## Opens a connection to the redis server.
  result.db = db
  result.host = host
  result.port = port
  result.password = password
  result.timeout = timeout
  result.safe = safe
  result.socket = newSocket(buffered = false)
  result.socket.connect(host, port)

proc sendcmd*(r: Redis, command: string, a: varargs[string, `$`]) =
  var args0 = command.split()
  var cmd = ""
  cmd &= "*" & $(len(args0)+len(a)) & "\r\n"
  for arg in args0 & @a:
    cmd &= "$" & $(len(arg)) & "\r\n"
    cmd &= arg
    cmd &= "\r\n"
  #echo cmd
  r.socket.send(cmd)
    

proc parse_resp*(r: Redis): RESPObj = 
  var resp = ""
  r.socket.readLine(resp)
  #echo(resp)
  case resp
  of "$-1":
    result = RESPObj(kind: sString, strVal: nil)
  of "*-1":
    result = RESPObj(kind: sArray, rArray: @[] ) 
  else:
    var fb = resp[0]
    var resp2 = resp[1..^1]
    case fb
    of '+':
      result = RESPObj(kind: sString, strVal:resp2)
    of '-':
      var e: ref RedisError
      new(e)
      e.msg = resp2
      raise e
    of ':':
      result = RESPObj(kind: cInteger, intVal: parseInt(resp2))
    of '$':
      var resp3=""
      r.socket.readLine(resp3)
      result = RESPObj(kind: bString, bstrVal:resp3)
    of '*':
      var arr: seq[RESPObj]  = @[]
      for i in 1..parseInt(resp2):
        arr.add(parse_resp(r))
      result = RESPObj(kind: sArray, rArray: arr)
    else:
      discard

# proc keys*(r: Redis, a: varargs[string, `$`]): RESPobj =
#  ##Find all keys matching the given pattern
#  sendcmd(r,"KEYS",a)
#  result = parse_resp(r)
 
# proc hscan*(r: Redis, a: varargs[string, `$`]): RESPobj =
#  ##Incrementally iterate hash fields and associated values
#  sendcmd(r,"HSCAN",a)
#  result = parse_resp(r)
      
macro readCommandsFile(commandsFile: string): stmt =
  let cmdFile = slurp(commandsFile.strVal)
  var source = ""
  for line in cmdFile.splitLines:
    var chunks = split(line, '|')
    if line.len < 1:
      continue
    #if chunks.len != 2:
    #  error("not equal to 2, got: " & line)
    #source &= "echo \"" & chunks[0] & "\"\n"
    var cmdname = chunks[0].toLower.replace(" ","_").replace("-","_")
    if cmdname == "discard":
      cmdname = "discardMulti"
    elif cmdname == "object":
      cmdname = "redisobject"

    source &= "proc " & cmdname & "*(r: Redis, a: varargs[string, `$`]): RESPobj =\n"
    source &= " ##" & chunks[1] & "\n"
    source &= " sendcmd(r,\"" & chunks[0] & "\",a)\n"
    source &= " result = parse_resp(r)\n\n"
  #error(source)
  result = parseStmt(source)

readCommandsFile("commands.csv")

  


var r = open()
echo "keys: " & $r.keys("*")
echo "set a 1" & $r.set("a",1)
echo "get a" & $r.get("a")
echo "incr b" & $r.incr("b")
echo "get f" & $r.get("f")
echo "get f f: " & $r.get("f","f")


