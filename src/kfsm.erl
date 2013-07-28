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
   start/3,
   start/4,
   start_link/3,
   start_link/4,
   behaviour_info/1
]).

-type(name() :: {local, atom()} | {global, atom()}).

-define(CONTAINER, kfsm_machine).

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
%% start fsm process
-spec(start/3 :: (atom(), list(), list()) -> {ok, pid()} | {error, any()}).
-spec(start/4 :: (name(), atom(), list(), list()) -> {ok, pid()} | {error, any()}).
-spec(start_link/3 :: (atom(), list(), list()) -> {ok, pid()} | {error, any()}).
-spec(start_link/4 :: (name(), atom(), list(), list()) -> {ok, pid()} | {error, any()}).

start(Mod, Args, Opts) ->
   gen_server:start(?CONTAINER, [Mod, Args], Opts).
start(Name, Mod, Args, Opts) ->
   gen_server:start(Name, ?CONTAINER, [Mod, Args], Opts).

start_link(Mod, Args, Opts) ->
   gen_server:start_link(?CONTAINER, [Mod, Args], Opts).
start_link(Name, Mod, Args, Opts) ->
   gen_server:start_link(Name, ?CONTAINER, [Mod, Args], Opts).

