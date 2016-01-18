Minimalist self generating redis client


You can test it with :
test with nim compile --run test.nim

and get the following output

keys: [ a b ]
set a 1OK
get a1
incr b26
get fnil
Traceback (most recent call last)
desir.nim(151)           desir
macros.nim(644)          get
desir.nim(92)            parse_resp
Error: unhandled exception: ERR wrong number of arguments for 'get' command [RedisError]

