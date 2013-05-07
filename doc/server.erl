-module(server).

-export([
   start_link/0, ping/1,
   init/1, free/2, handle/2, 
]).

start_link() ->
   kfsm:start_link({local, ?MODULE}, ?MODULE, []).

init(_) ->
   {ok, handle, undefined}.

free(_, _) ->
   ok.

ping(Pid) ->
   kfsm:call(Pid, ping).

handle(ping, S) ->
   {reply, pong, handle, S}.