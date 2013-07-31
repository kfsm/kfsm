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
   init/1, 
   terminate/2,
   handle_call/3,
   handle_cast/2,
   handle_info/2,
   code_change/3
]).

%% internal state
-record(machine, {
   mod   :: atom(),  %% FSM implementation
   sid   :: atom(),  %% FSM state (transition function)
   state :: any()    %% FSM internal data structure
}).

%%%----------------------------------------------------------------------------   
%%%
%%% Factory
%%%
%%%----------------------------------------------------------------------------   

init([Mod, Args]) ->
   init(Mod:init(Args), #machine{mod=Mod}).

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
handle_call({ioctl, Req, Val}, _Tx, #machine{mod=Mod}=S) ->
   % ioctl set request
   ?DEBUG("pipe ioctl ~p: req ~p, val ~p~n", [self(), Req, Val]),
   try
      {reply, Val, S#machine{state = Mod:ioctl({Req, Val}, S#machine.state)}}
   catch _:_ ->
      {reply, Val, S}
   end;

handle_call({ioctl, Req}, _Tx, #machine{mod=Mod}=S) ->
   % ioctl get request
   ?DEBUG("pipe ioctl ~p: req ~p~n", [self(), Req]),
   try
      {reply, Mod:ioctl(Req, S#machine.state), S}
   catch _:_ ->
      {reply, undefined, S}
   end;

handle_call(Msg0, Tx, #machine{mod=Mod, sid=Sid0}=S) ->
   % synchronous out-of-bound call to machine
   ?DEBUG("kfsm call ~p: tx ~p, msg ~p~n", [self(), Tx, Msg0]),
   case Mod:Sid0(Msg0, Tx, S#machine.state) of
      {next_state, Sid, State} ->
         {noreply, S#machine{sid=Sid, state=State}};
      {next_state, Sid, State, TorH} ->
         {noreply, S#machine{sid=Sid, state=State}, TorH};
      {stop, Reason, State} ->
         {stop, Reason, S#machine{state=State}}
   end.

%%
%%
handle_cast(_, S) ->
   {noreply, S}.

%%
%%
handle_info({'$req', Tx, Msg0}, #machine{mod=Mod, sid=Sid0}=S) ->   
   % in-bound call to FSM
   ?DEBUG("kfsm cast ~p: tx ~p, msg ~p~n", [self(), Tx, Msg0]),
   case Mod:Sid0(Msg0, Tx, S#machine.state) of
      {next_state, Sid, State} ->
         {noreply, S#machine{sid=Sid, state=State}};
      {next_state, Sid, State, TorH} ->
         {noreply, S#machine{sid=Sid, state=State}, TorH};
      {stop, Reason, State} ->
         {stop, Reason, S#machine{state=State}}
   end;

handle_info(Msg0, #machine{mod=Mod, sid=Sid0}=S) ->
   %% out-of-bound message
   ?DEBUG("kfsm recv ~p: msg ~p~n", [self(), Msg0]),
   case Mod:Sid0(Msg0, undefined, S#machine.state) of
      {next_state, Sid, State} ->
         {noreply, S#machine{sid=Sid, state=State}};
      {next_state, Sid, State, TorH} ->
         {noreply, S#machine{sid=Sid, state=State}, TorH};
      {stop, Reason, State} ->
         {stop, Reason, S#machine{state=State}}
   end.

%%
%%
code_change(_Vsn, S, _) ->
   {ok, S}.

%%%----------------------------------------------------------------------------   
%%%
%%% private
%%%
%%%----------------------------------------------------------------------------   


