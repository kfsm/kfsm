%% @description
%%    example pass pipe
-module(kfsm_pipe_pass).
-include("kfsm.hrl").

-export([
   init/1, free/2, pass/3
]).

init(_) ->
   {ok, pass, undefined}.

free(_, _) ->
   ok.

pass(Msg, Pipe, S) ->
   ?DEBUG("kfsm pass: ~p pipe ~p", [Msg, Pipe]),
   _ = plib:ack(Pipe,  ack),
   _ = plib:send(Pipe, Msg),
   {next_state, pass, S}.

