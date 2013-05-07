-module(kfsm_tests).
-include_lib("eunit/include/eunit.hrl").

kfsm_test_() ->
   {
      setup,
      fun init/0,
      fun free/1,
      [
          {"cast success",    fun cast_success/0}
         ,{"cast failure",    fun cast_failure/0}

         ,{"call success",    fun call_success/0}
         ,{"call failure",    fun call_failure/0}

         ,{"send success",    fun send_success/0}
         ,{"send failure",    fun send_failure/0}

         ,{"long cast success",    fun long_cast_success/0}
         ,{"long call success",    fun long_call_success/0}
         ,{"long send success",    fun long_send_success/0}
      ]
   }.

init() ->
   {ok, Pid} = kfsm:start_link(kfsm_echo, []),
   erlang:register('FSM', Pid),
   Pid.

free(Pid) ->
   erlang:unlink(Pid),
   erlang:exit(Pid, shutdown).


cast_success() ->
   Ref1 = kfsm:cast('FSM', message),
   receive {ok, Ref1, message} -> ok end.

long_cast_success() ->
   Ref1 = kfsm:cast('FSM', ping),
   receive {ok, Ref1, pong} -> ok end.

cast_failure() ->
   Ref2 = kfsm:cast('FSM', badarg),
   receive {error, Ref2, badarg} -> ok end.


call_success() ->
   {ok, message} = kfsm:call('FSM', message),
   {ok, message} = gen_server:call('FSM', message).

long_call_success() ->
   {ok, pong} = kfsm:call('FSM', ping),
   {ok, pong} = gen_server:call('FSM', ping).

call_failure() ->
   {error, badarg} = kfsm:call('FSM', badarg),
   {error, badarg} = gen_server:call('FSM', badarg).
   

send_success() ->
   ok = kfsm:send('FSM', message),
   receive message -> ok end.

long_send_success() ->
   ok = kfsm:send('FSM', ping),
   receive pong -> ok end.

send_failure() ->
   ok = kfsm:send('FSM', badarg),
   receive badarg -> ok end.


