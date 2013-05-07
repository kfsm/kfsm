-module(kfsm_echo).

-export([
   init/1, free/2, echo/2
]).

init(_) ->
   {ok, echo, undefined}.

free(_, _) ->
   ok.

echo(badarg, S) ->
   {error, badarg, echo, S};

echo(ping,   S)  ->
   {next_state, echo, S, 100};

echo(timeout, S) ->
   {reply, pong, echo, S};

echo(Msg, S) ->
   {reply, Msg,    echo, S}.