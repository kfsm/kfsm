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
%%   
-module(kfsm).
-include("kfsm.hrl").

-export([
   start_link/1, cast/2, call/2, call/3, send/2
]).

-type(fsm() :: atom() | pid() | any()).
-type(msg() :: any()).

%%
%% The function creates a new container process for state machine.
%% The function Mod:init is called to build internal state data state
%% and defines initial state (transition function) sid. 
-spec(start_link/1 :: (atom()) -> {ok, pid()} | {error, any()}).

start_link(Mod) ->
   kfsm_machine:start_link(Mod).

%%
%% the cast operation sends any message to the state machine and 
%% immediately returns unique reference. The reference allows to 
%% asynchronously “wait” for either any successful or any unsuccessful
%% response (e.g. response message signature is {ok|error,ref,any}).
%% the reference is automatically generated using erlang:make_ref
-spec(cast/2 :: (fsm(), msg()) -> reference()).

cast(FSM, Msg) ->
   Ref = erlang:make_ref(),
   erlang:send(FSM, {kfsm, {self(), Ref}, Msg}),
   Ref.

%%
%% the call operation sends any message to the state machine and 
%% waits for either any successful or any unsuccessful response
-spec(call/2 :: (fsm(), msg()) -> {ok, msg()} | {error, any()}).
-spec(call/3 :: (fsm(), msg(), timeout()) -> {ok, msg()} | {error, any()}).

call(FSM, Msg) ->
   call(FSM, Msg, 5000).
call(FSM, Msg, Timeout) ->
   %% TODO: make distributed
   Ref = erlang:make_ref(),
   Mon = erlang:monitor(process, FSM),
   erlang:send(FSM, {kfsm, {self(), Ref}, Msg}),
   receive
      {ok, Ref, Reply} ->
         erlang:demonitor(Mon, [flush]),
         {ok, Reply};
      {error, Ref, Reason} ->
         erlang:demonitor(Mon, [flush]),
         {error, Reason};
      {'DOWN', Mon, _, _, Reason} ->
         throw(Reason)
   after Timeout ->
      erlang:demonitor(Mon, [flush]),
      throw(timeout)
   end.

%%
%%
-spec(send/2 :: (fsm(), msg()) -> ok).

send(FSM, Msg) ->
   erlang:send(FSM, {kfsm, self(), Msg}),
   ok.



