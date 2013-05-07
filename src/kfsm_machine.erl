%%
%%   Copyright (c) 2012 - 2013, Dmitry Kolesnikov
%%   Copyright (c) 2012 - 2013, Mario Cardona
%%   All Rights Reserved.
%%
%%   Licensed under the Apache License, Version 2.0 (the "License");
%%   you may not use this file except in compliance with the License.
%%   You may obtain a copy of the License at
%%
%%       http://www.apache.org/licenses/LICENSE-2.0
%%
%%   Unless required by applicable law or agreed to in writing, software
%%   distributed under the License is distributed on an "AS IS" BASIS,
%%   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%   See the License for the specific language governing permissions and
%%   limitations under the License.
%%
%% @description
%%    state machine container
-module(kfsm_machine).
-behaviour(gen_server).
-include("kfsm.hrl").

-export([
   start_link/2, 
   init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3
]).

%% internal state
-record(machine, {
   mod   :: atom(),  %% FSM implementation
   sid   :: atom(),  %% FSM state (transition function)
   state :: any(),   %% FSM internal data structure
   q     :: any()    %% FSM request queue
}).


%%
%%
start_link(Mod, Args) ->
   gen_server:start_link(?MODULE, [Mod, Args], []).

init([Mod, Args]) ->
   init(Mod:init(Args), #machine{mod=Mod, q=q:new()}).

init({ok, Sid, State}, S) ->
   {ok, S#machine{sid=Sid, state=State}};
init({error,  Reason}, _) ->
   {stop, Reason}.   

terminate(Reason, #machine{mod=Mod}=S) ->
   Mod:free(Reason, S#machine.state).   

%%%----------------------------------------------------------------------------   
%%%
%%% gen_server
%%%
%%%----------------------------------------------------------------------------   

%%
%%
handle_call(Msg, Tx, #machine{mod=Mod, sid=Sid}=S) ->
   ?DEBUG("kfsm call ~p: tx ~p, msg ~p~n", [self(), Tx, Msg]),
   handle_result(Mod:Sid(Msg, S#machine.state), {gen, Tx}, S).

%%
%%
handle_cast(_, S) ->
   {noreply, S}.

%%
%%
handle_info({kfsm, Tx, Msg}, #machine{mod=Mod, sid=Sid}=S) ->   
   ?DEBUG("kfsm cast ~p: tx ~p, msg ~p~n", [self(), Tx, Msg]),
   handle_result(Mod:Sid(Msg, S#machine.state), Tx, S);

handle_info(Msg, #machine{mod=Mod, sid=Sid}=S) ->
   ?DEBUG("kfsm recv ~p: msg ~p~n", [self(), Msg]),
   handle_result(Mod:Sid(Msg, S#machine.state), undefined, S).

%%
%%
code_change(_Vsn, S, _) ->
   {ok, S}.

%%%----------------------------------------------------------------------------   
%%%
%%% private
%%%
%%%----------------------------------------------------------------------------   

handle_result(Result, undefined, S) ->
   {Tx, Q} = q:deq(S#machine.q),   
   handle_result(Result, Tx, S#machine{q=Q});

handle_result({next_state, Sid, State}, Tx, S) ->
   {noreply, S#machine{sid=Sid, state=State, q=enq(Tx, S)}};

handle_result({next_state, Sid, State, TorH}, Tx, S) ->
   {noreply, S#machine{sid=Sid, state=State, q=enq(Tx, S)}, TorH};

handle_result({reply, Msg, Sid, State}, Tx, S) ->
   ack(Msg, Tx),
   {noreply, S#machine{sid=Sid, state=State}};

handle_result({reply, Msg, Sid, State, TorH}, Tx, S) ->
   ack(Msg, Tx),
   {noreply, S#machine{sid=Sid, state=State}, TorH};

handle_result({error, Msg, Sid, State}, Tx, S) ->
   nack(Msg, Tx),
   {noreply, S#machine{sid=Sid, state=State}};

handle_result({error, Msg, Sid, State, TorH}, Tx, S) ->
   nack(Msg, Tx),
   {noreply, S#machine{sid=Sid, state=State}, TorH};

handle_result({stop, Msg, Reason, State}, Tx, S) ->
   ack(Msg, Tx),
   {stop, Reason, S#machine{state=State}};

handle_result({stop, Reason, State}, Tx, S) ->
   {stop, Reason, S#machine{state=State}}.


%%
%% acknowledge transaction
ack(Msg, {Pid, Ref}=Tx)
 when is_pid(Pid) ->
   ?DEBUG("kfsm reply ~p: tx ~p, msg ~p~n", [self(), Tx, Msg]),
   erlang:send(Pid, {ok, Ref, Msg});

ack(Msg, Pid)
 when is_pid(Pid) ->
   ?DEBUG("kfsm reply ~p: tx ~p, msg ~p~n", [self(), Pid, Msg]),
   erlang:send(Pid, Msg);

ack(Msg, {gen, Tx}) ->
   ?DEBUG("kfsm reply ~p: tx ~p, msg ~p~n", [self(), Tx, Msg]),
   gen_server:reply(Tx, {ok, Msg});

ack(_, _) ->
   ok. %% Tx reference undefined


nack(Msg, {Pid, Ref}=Tx)
 when is_pid(Pid) ->
   ?DEBUG("kfsm error ~p: tx ~p, msg ~p~n", [self(), Tx, Msg]),
   erlang:send(Pid, {error, Ref, Msg});

nack(Msg, Pid)
 when is_pid(Pid) ->
   ?DEBUG("kfsm error ~p: tx ~p, msg ~p~n", [self(), Pid, Msg]),
   erlang:send(Pid, Msg); %% (?)

nack(Msg, {gen, Tx}) ->
   ?DEBUG("kfsm error ~p: tx ~p, msg ~p~n", [self(), Tx, Msg]),
   gen_server:reply(Tx, {error, Msg});

nack(_, _) ->
   ok. %% Tx reference undefined

%%
%% enqueue transaction
enq(undefined, S) ->
   S#machine.q;

enq(Msg, S) ->
   q:enq(Msg, S#machine.q).




