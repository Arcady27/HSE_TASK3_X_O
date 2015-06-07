-module(logic).
-behaviour(gen_server).
-export([terminate/2,init/1, start_link/0, handle_call/3, handle_cast/2]).
-export([checkTurn/4, getWinner/1, addPlayer/2,getPlayers/1, getSymbols/1,verifyCell/3,start_game/0,leave_game/2, diff/2, del_nth_from_list/2 ]).
-record(situation, {players = queue:new(), symbols = queue:new(), winner=no, field = dict:new()}).
%%% Реализация процесса игровой логики
%%%   start_link – запуск процесса
%%%   init – создание начального состояния
%%%   handle_call – обработка сообщений, которые требуют ответ
%%%   handle_cast – обработка сообщений, которые не требуют ответs
start_link() -> gen_server:start_link({global, logic}, ?MODULE, [], []).
init([]) -> { ok, logic:start_game() }.
handle_call( {getPlayers} , _, State) -> { reply, getPlayers(State), State } ;
handle_call( {getSymbols} , _, State) -> { reply, getSymbols(State), State } ;
handle_call( {getWinner} , _, State) -> {reply, getWinner(State), State};
handle_call( {verifyCell, X, Y}, _, State) -> {reply, verifyCell(X, Y, State), State};
handle_call( {getField}, _, State) -> {reply, State#situation.field, State};

handle_call( {makeTurn, PlayerName, X, Y}, _, State) ->
  {Status, NewState} = logic:checkTurn(X, Y, PlayerName, State),
  {reply, Status, NewState};

handle_call( {join, Name}, _, State) ->
  {Status, NewState} = addPlayer(Name, State),
  {reply, Status, NewState}.

handle_cast( {reset}, _ ) -> {noreply, #situation{}};

handle_cast( {leave, Name}, State) -> {noreply, leave_game(Name, State)}.

checkTurn(X,Y,PlayerName,State) ->
  Current = queue:head(State#situation.players),
  CellIsFree = verifyCell(X,Y,State),
  if Current == PlayerName ->
    if CellIsFree == free ->
      if State#situation.winner == no -> makeTurn(X,Y,PlayerName,State);
        State#situation.winner /= no -> {end_game,State}
      end;
      CellIsFree /= free -> {busy,State}
    end;
    Current /= PlayerName -> {not_your_turn, State}
  end.


getPlayers(State) ->
  %erlang:display(State#situation.players),
  %erlang:display(queue:head(State#situation.players)),
  queue:to_list(State#situation.players).

getSymbols(State) ->
  %erlang:display(State#situation.players),
  %erlang:display(queue:head(State#situation.players)),
  queue:to_list(State#situation.symbols).

getWinner(State) ->
  erlang:display(State#situation.winner),
  State#situation.winner.

verifyCell(X, Y, State) ->
  Field = State#situation.field,
  A = dict:find({X,Y},Field),
  if A == error -> free;
    A /= error -> ok
  end.

makeTurn(X,Y,PlayerName,State) ->
  Name = PlayerName,
  Field = dict:append({X,Y},Name,State#situation.field),
  %erlang:display(Field),
  Won = checkGame(X,Y,Name,Field),
  %erlang:display(Won),
  if Won == Name ->
    {end_game,State#situation{winner = Name,field = Field}};

    Won /= Name ->
      {{value, Current}, TmpQueue} = queue:out(State#situation.players),
      NewQueue = queue:in(Current, TmpQueue),
      erlang:display(NewQueue),
      %{no_winner,State#situation{players = NewQueue, field = Field}},

      {{value, CurrentSymbol}, TmpQueueSymbols} = queue:out(State#situation.symbols),
      NewSymbols = queue:in(CurrentSymbol, TmpQueueSymbols),
      erlang:display(NewSymbols),
      {no_winner,State#situation{symbols  = NewSymbols, field = Field,players = NewQueue}}


  end.

checkGame(X,Y,Name,Field) ->
  N = 5,
  Bool = checkLine(X,Y,Name,Field,N),
  if Bool == true -> Name;
    Bool /= true -> no_winner
  end.

checkLine(X,Y,Name,Field,N) ->
  Hor = checkLine(X,Y,Name,Field,right,N) - checkLine(X,Y,Name,Field,left,N) - 1,
  Ver = checkLine(X,Y,Name,Field,up,N) - checkLine(X,Y,Name,Field,down,N) - 1,
  Diag_up = checkLine(X,Y,Name,Field,right_up,N) - checkLine(X,Y,Name,Field,left_down,N) - 1,
  Diag_down =  checkLine(X,Y,Name,Field,right_down,N) - checkLine(X,Y,Name,Field,left_up,N) - 1,
if ((Hor == N) or (Ver == N) or (Diag_up == N) or (Diag_down == N)) -> true;
  true -> false
end.

checkLine(X,Y,Name,Field,Dir,N) ->
  A = dict:find({X,Y},Field),
  io:write(A),
  case Dir of
    right ->
      case dict:find({X,Y},Field) of {ok, [Name]} -> checkLine(X+1,Y,Name,Field,Dir,N);
        _ ->  X
      end;
    left ->
      case dict:find({X,Y},Field) of {ok, [Name]} -> checkLine(X-1,Y,Name,Field,Dir,N);
        _Else -> X
      end;
    up ->
      case dict:find({X,Y},Field) of {ok, [Name]} -> checkLine(X,Y+1,Name,Field,Dir,N);
        _Else -> Y
      end;
    down ->
      case dict:find({X,Y},Field) of {ok, [Name]} -> checkLine(X,Y-1,Name,Field,Dir,N);
        _Else -> Y
      end;
    right_up ->
      case dict:find({X,Y},Field) of {ok, [Name]} -> checkLine(X+1,Y+1,Name,Field,Dir,N);
        _Else -> X
      end;
    left_up ->
      case dict:find({X,Y},Field) of {ok, [Name]} -> checkLine(X-1,Y+1,Name,Field,Dir,N);
        _Else -> X
      end;
    right_down ->
      case dict:find({X,Y},Field) of {ok, [Name]} -> checkLine(X+1,Y-1,Name,Field,Dir,N);
        _Else -> X
      end;
    left_down ->
      case dict:find({X,Y},Field) of {ok, [Name]} -> checkLine(X-1,Y-1,Name,Field,Dir,N);
        _Else -> X
      end
  end.


diff(L1, L2) ->
  %erlang:display(L1),
  %erlang:display(L2),
  erlang:filter(fun(X) -> not erlang:member(X, L2) end, L1).

addPlayer(Name, State) ->
  Players = State#situation.players,
  Bool_c = queue:member(Name,Players),
  if Bool_c == true -> {not_ok, State};
     Bool_c /= true ->
          NewPlayers = queue:in(Name, State#situation.players),

          erlang:display(NewPlayers),
          %AllSymbolslist = lists:append([["X"], ["O"], ["*"], ["&"], ["%"], ["V"], ["#"], ["@"], [">"], ["<"]]),
          AllSymbolsList =["X", "O", "*", "&", "%", "V", "#", "@", ">", "<"],
          AllSymbols = queue:from_list(AllSymbolsList),
          erlang:display(State#situation.symbols),

       Bool_l = queue:is_empty(State#situation.symbols),
          if Bool_l==true -> Differ = queue:from_list(AllSymbolsList);
             Bool_l/=true ->
              Differ = queue:filter(fun(X) -> not queue:member(X, State#situation.symbols) end, AllSymbols)
           end,

          Symbol = queue:head(Differ),
          NewSymbols = queue:in(Symbol, State#situation.symbols),
          {ok, State#situation{symbols =  NewSymbols,players = NewPlayers}}
  end
.
index_of(Elem, List) ->
  {Map, _} = lists:mapfoldr(fun(X, I) -> {{X, I}, I + 1} end, 0, List),
  {_, Index} = lists:keyfind(Elem, 1, Map), Index.

del_nth_from_list(List, N) ->
  Elem = lists:nth(N,List),
  %erlang:display(Elem),
  lists:delete(Elem,List).

leave_game(Name,State) ->
  Players = State#situation.players,

  Index = index_of(Name,queue:to_list(Players)),
  NewPlayers = del_nth_from_list(queue:to_list(Players),Index),
  %erlang:display(Index),

  Symbols = State#situation.symbols,
  NewSymbols = del_nth_from_list(queue:to_list(Symbols),Index),
  %erlang:display(NewSymbols),

  State#situation {symbols  = queue:from_list(NewSymbols), players = queue:from_list(NewPlayers)}
.

start_game() -> #situation{}

.

terminate(_Reason, _State) -> ok.