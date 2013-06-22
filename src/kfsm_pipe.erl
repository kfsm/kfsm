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
%%    pipe container
-module(kfsm_pipe).
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
   a     :: pid(),   %% pipe side (a) // source
   b     :: pid()    %% pipe side (b) // sink
}).


%%
%% Opts allows to bind pipe at construction
start_link(Mod, Args) ->
   gen_server:start_link(?MODULE, [Mod, Args], []).

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

handle_call(Msg0, Tx, #machine{mod=Mod, sid=Sid0}=S) ->
   % synchronous out-of-bound call to machine   
   ?DEBUG("kfsm call ~p: tx ~p, msg ~p~n", [self(), Tx, Msg0]),
   case Mod:Sid0(Msg0, pipe:make(Tx, S#machine.a, S#machine.b), S#machine.state) of
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
handle_info({'$pipe', '$a', Pid}, S) ->
   ?DEBUG("kfsm pipe ~p: a to ~p", [self(), Pid]),
   {noreply, S#machine{a=Pid}};

handle_info({'$pipe', '$b', Pid}, S) ->
   ?DEBUG("kfsm pipe ~p: b to ~p", [self(), Pid]),
   {noreply, S#machine{b=Pid}};

handle_info({'$pipe', Tx, Msg}, #machine{mod=Mod, sid=Sid0}=S) ->   
   %% in-bound call to FSM
   ?DEBUG("kfsm pipe ~p: tx ~p, msg ~p~n", [self(), Tx, Msg]),
   case Mod:Sid0(Msg, pipe:make(Tx, S#machine.a, S#machine.b), S#machine.state) of
      {next_state, Sid, State} ->
         {noreply, S#machine{sid=Sid, state=State}};
      {next_state, Sid, State, TorH} ->
         {noreply, S#machine{sid=Sid, state=State}, TorH};
      {stop, Reason, State} ->
         {stop, Reason, S#machine{state=State}}
   end;

handle_info({'$req', Tx, Msg0}, #machine{mod=Mod, sid=Sid0}=S) ->   
   %% in-bound call to FSM
   ?DEBUG("kfsm cast ~p: tx ~p, msg ~p~n", [self(), Tx, Msg0]),
   case Mod:Sid0(Msg0, pipe:make(Tx, S#machine.a, S#machine.b), S#machine.state) of
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
   case Mod:Sid0(Msg0, {pipe, S#machine.a, S#machine.b}, S#machine.state) of
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

