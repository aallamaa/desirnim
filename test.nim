import desir

var r = desir.open()
echo "keys: " & $r.keys("*")
echo "set a 1" & $r.set("a",1)
echo "get a" & $r.get("a")
echo "incr b" & $r.incr("b")
echo "get f" & $r.get("f")
echo "get f f: " & $r.get("f","f")
