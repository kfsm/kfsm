-module(tcp).

%%
%% start new tcp/ip state machine
-spec(start_link/0 :: () -> {ok, pid()} | {error, any()}).

start_link() ->
   kfsm:start_link(?MODULE, []).

%%
%% synchronous / asynchronous connect 
-spec(connect/2  :: (pid(), peer()) -> {ok, peer()} | {error, any()}).
-spec(connect_/2 :: (pid(), peer()) -> reference()).

connect(Pid, Peer) ->
   % call is blocked until socket is connected
   kfsm:call(Pid, {connect, Peer}).

connect_(Pid, Peer) ->
   % call is released immediately the message 
   % {xxx, xxx, {ok, Peer}} is delivered to mailbox
   % when socket is connected
   kfsm:cast(Pid, {connect, Peer}).

%%
%% synchronous / asynchronous message send
-spec(send/2  :: (pid(), binary()) -> ok | {error, any()}).
-spec(send_/2 :: (pid(), binary()) -> reference()).

send(Pid, Msg) ->
   kfsm:call(Pid, {send, Msg}).

send_(Pid, Msg) ->
   % call is released immediately the message 
   % {xxx, xxx, ok} is delivered to mailbox
   % when socket is connected
   kfsm:cast(Pid, {send, Msg}).

%%
%% synchronous / asynchronous message recv
-spec(recv/1  :: (pid()) -> {ok, binary()} | {error, any()}).
-spec(recv_/1 :: (pid()) -> reference()).

send(Pid, Msg) ->
   kfsm:call(Pid, recv).

send_(Pid, Msg) ->
   % call is released immediately the message 
   % {xxx, xxx, {ok, binary()}} is delivered to mailbox
   % when socket is connected
   kfsm:cast(Pid, recv).
   




