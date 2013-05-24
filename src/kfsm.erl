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
   start_link/2, join/1, join/2, 
   cast/2, call/2, call/3, send/2,

   %%
   behaviour_info/1
]).

-type(fsm() :: atom() | pid() | any()).
-type(msg() :: any()).

%%
%% 
behaviour_info(callbacks) ->
   [
      {init, 1}
     ,{free, 2}
   ];
behaviour_info(_Other) ->
    undefined.

%%
%% TODO: gen_server compatible
%%
%% The function creates a new container process for state machine.
%% The function Mod:init is called to build internal state data state
%% and defines initial state (transition function) sid. 
-spec(start_link/2 :: (atom(), list()) -> {ok, pid()} | {error, any()}).

start_link(Mod, Opts) ->
   kfsm_machine:start_link(Mod, Opts).

%%
%% join external process to fsm
-spec(join/1 :: (fsm()) -> ok | {error, any()}).
-spec(join/2 :: (fsm(), pid()) -> ok | {error, any()}).

join(Pid) ->
   join(Pid, self()).

join(Pid, A) ->
   gen_server:call(Pid, {kfsm_join, A}).

%%
%% the cast operation sends any message to the state machine and 
%% immediately returns unique reference. The reference allows to 
%% asynchronously “wait” for either any successful or any unsuccessful
%% response (e.g. response message signature is {ok|error,ref,any}).
%% the reference is automatically generated using erlang:make_ref
-spec(cast/2 :: (fsm(), msg()) -> reference()).

cast(Pid, Msg) ->
   plib:cast(Pid, Msg).

%%
%% the call operation sends any message to the state machine and 
%% waits for either any successful or any unsuccessful response
-spec(call/2 :: (fsm(), msg()) -> msg()).
-spec(call/3 :: (fsm(), msg(), timeout()) -> msg()).

call(Pid, Msg) ->
   call(Pid, Msg, 5000).

call(Pid, Msg, Timeout) ->
   plib:call(Pid, Msg, Timeout).

%%
%%
-spec(send/2 :: (fsm(), msg()) -> ok).

send(Pid, Msg) ->
   plib:send(Pid, Msg).



