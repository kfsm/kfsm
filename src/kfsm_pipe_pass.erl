%% @description
%%    example pass pipe
-module(kfsm_pipe_pass).
-include("kfsm.hrl").

-export([
   start_link/0, init/1, free/2, pass/3
]).

start_link() ->
   kfsm_pipe:start_link(?MODULE, []).

init(_) ->
   {ok, pass, undefined}.

free(_, _) ->
   ok.

pass(Msg, Pipe, S) ->
   ?DEBUG("kfsm pass: ~p pipe ~p", [Msg, Pipe]),
   _ = pipe:'>'(Pipe, Msg),
   {next_state, pass, S}.

