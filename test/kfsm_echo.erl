-module(kfsm_echo).

-export([
   init/1, free/2, echo/3
]).

init(_) ->
   {ok, echo, undefined}.

free(_, _) ->
   ok.

%% error
echo(badarg, Tx, S) ->
   plib:ack(Tx, {error, badarg}),
   {next_state, echo, S};

%% long tx
echo(ping, Tx, S)  ->
   {next_state, echo, Tx, 100};
echo(timeout, _, S) ->
   plib:ack(S, pong),
   {next_state, echo, undefined};

%% echo
echo(Msg, Tx, S) ->
   plib:ack(Tx, Msg),
   {next_state, echo, S}.