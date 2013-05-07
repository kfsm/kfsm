-module(tcp).

...

'IDLE'({connect, Peer}, S) ->
   {ok, Sock} = gen_tcp:connect(...),
   {reply, {ok, Peer}, 'ESTABLISHED', S#tcp{sock=Sock}};

...

'ESTABLISHED'({send, Msg}, S) ->
   Result = gen_tcp:send(S#tcp.sock, Msg),
   {reply, Result, 'ESTABLISHED'};

...

'ESTABLISHED'({recv, Msg}, S) ->
   Result = gen_tcp:recv(S#tcp.sock, 0),
   {reply, Result, 'ESTABLISHED'};

