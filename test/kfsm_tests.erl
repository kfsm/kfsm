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

         ,{"emit success",    fun emit_success/0}
         ,{"emit failure",    fun emit_failure/0}

         ,{"long cast success",    fun long_cast_success/0}
         ,{"long call success",    fun long_call_success/0}
         ,{"long send success",    fun long_emit_success/0}
      ]
   }.

init() ->
   {ok, Pid} = kfsm:start_link(kfsm_echo, [], []),
   erlang:register('FSM', Pid),
   Pid.

free(Pid) ->
   erlang:unlink(Pid),
   erlang:exit(Pid, shutdown).


cast_success() ->
   Ref1 = plib:cast('FSM', message),
   receive {Ref1, message} -> ok end.

long_cast_success() ->
   Ref1 = plib:cast('FSM', ping),
   receive {Ref1, pong} -> ok end.

cast_failure() ->
   Ref2 = plib:cast('FSM', badarg),
   receive {Ref2, {error, badarg}} -> ok end.


call_success() ->
   message = plib:call('FSM', message),
   message = gen_server:call('FSM', message).

long_call_success() ->
   pong = plib:call('FSM', ping),
   pong = gen_server:call('FSM', ping).

call_failure() ->
   {error, badarg} = plib:call('FSM', badarg),
   {error, badarg} = gen_server:call('FSM', badarg).
   

emit_success() ->
   ok = plib:emit('FSM', message),
   receive message -> ok end.

long_emit_success() ->
   ok = plib:emit('FSM', ping),
   receive pong -> ok end.

emit_failure() ->
   ok = plib:emit('FSM', badarg),
   receive {error, badarg} -> ok end.


