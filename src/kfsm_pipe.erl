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
   start_link/3, 
   init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3
]).

%% internal state
-record(machine, {
   mod   :: atom(),  %% FSM implementation
   sid   :: atom(),  %% FSM state (transition function)
   state :: any(),   %% FSM internal data structure
   a     :: pid(),   %% pipe sideA
   b     :: pid()    %% pipe sideB
}).


%%
%% Opts allows to bind pipe at construction
start_link(Mod, Args, Opts) ->
   gen_server:start_link(?MODULE, [Mod, Args, Opts], []).

init([Mod, Args, Opts]) ->
   init(
      Mod:init(Args), 
      init_pipe(Opts, #machine{mod=Mod})
   ).

init({ok, Sid, State}, S) ->
   {ok, S#machine{sid=Sid, state=State}};
init({error,  Reason}, _) ->
   {stop, Reason}.   

init_pipe(Opts, S) ->
   maybe_init_pipeA(
      opts:val(pipeA, undefined, Opts),
      maybe_init_pipeB(
         opts:val(pipeA, undefined, Opts), S
      )
   ).

maybe_init_pipeA(undefined, S) ->
   S;
maybe_init_pipeA(Pid, S) ->
   ok = gen_server:call(Pid, {kfsm_pipe_b, self()}),
   S#machine{a=Pid}.

maybe_init_pipeB(undefined, S) ->
   S;
maybe_init_pipeB(Pid, S) ->
   ok = gen_server:call(Pid, {kfsm_pipe_a, self()}),
   S#machine{a=Pid}.

terminate(Reason, #machine{mod=Mod}=S) ->
   Mod:free(Reason, S#machine.state).   

%%%----------------------------------------------------------------------------   
%%%
%%% gen_server
%%%
%%%----------------------------------------------------------------------------   

%%
%%
handle_call({kfsm_pipe_a, Pid}, _, S) ->
   ?DEBUG("kfsm set a: ~p to ~p", [self(), Pid]),
   {reply, ok, S#machine{a=Pid}};

handle_call({kfsm_pipe_b, Pid}, _, S) ->
   ?DEBUG("kfsm set b: ~p to ~p", [self(), Pid]),
   {reply, ok, S#machine{b=Pid}};


handle_call(Msg0, Tx, #machine{mod=Mod, sid=Sid0}=S) ->
   % synchronous out-of-bound call to machine
   % either reply or queue request tx
   ?DEBUG("kfsm call ~p: tx ~p, msg ~p~n", [self(), Tx, Msg0]),
   case Mod:Sid0(Msg0, pipe(Tx, S#machine.a, S#machine.b), S#machine.state) of
      {next_state, Sid, State} ->
         {noreply, S#machine{sid=Sid, state=State}};
      {next_state, Sid, State, TorH} ->
         {noreply, S#machine{sid=Sid, state=State}, TorH};
      {self,  Msg, Sid, State} ->
         self() ! Msg,
         {noreply, S#machine{sid=Sid, state=State}};
      {stop, Reason, State} ->
         {stop, Reason, S#machine{state=State}}
   end.

%%
%%
handle_cast(_, S) ->
   {noreply, S}.

%%
%%
handle_info({'$pipe', Tx, Msg}, #machine{mod=Mod, sid=Sid0}=S) ->   
   %% in-bound call to FSM
   ?DEBUG("kfsm pipe ~p: tx ~p, msg ~p~n", [self(), Tx, Msg]),
   case Mod:Sid0(Msg, pipe(Tx, S#machine.a, S#machine.b), S#machine.state) of
      {next_state, Sid, State} ->
         {noreply, S#machine{sid=Sid, state=State}};
      {next_state, Sid, State, TorH} ->
         {noreply, S#machine{sid=Sid, state=State}, TorH};
      {self,  Msg, Sid, State} ->
         self() ! Msg,
         {noreply, S#machine{sid=Sid, state=State}};
      {stop, Reason, State} ->
         {stop, Reason, S#machine{state=State}}
   end;

handle_info({'$req', Tx, Msg0}, #machine{mod=Mod, sid=Sid0}=S) ->   
   %% in-bound call to FSM
   ?DEBUG("kfsm cast ~p: tx ~p, msg ~p~n", [self(), Tx, Msg0]),
   case Mod:Sid0(Msg0, pipe(Tx, S#machine.a, S#machine.b), S#machine.state) of
      {next_state, Sid, State} ->
         {noreply, S#machine{sid=Sid, state=State}};
      {next_state, Sid, State, TorH} ->
         {noreply, S#machine{sid=Sid, state=State}, TorH};
      {self,  Msg, Sid, State} ->
         self() ! Msg,
         {noreply, S#machine{sid=Sid, state=State}};
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
      {self,  Msg, Sid, State} ->
         self() ! Msg,
         {noreply, S#machine{sid=Sid, state=State}};
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

%% build i/o pipe
pipe(Tx, A, B) ->
   case plib:pid(Tx) of
      A -> 
         {pipe, Tx, B};
      B -> 
         {pipe, Tx, A};
      _ -> 
         case A of
            undefined -> {pipe, Tx, B};
            _         -> {pipe, Tx, A}
         end
   end.
