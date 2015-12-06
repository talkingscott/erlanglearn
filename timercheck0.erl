-module(timercheck).
-export([loop/3,start/0,stop/0]).

-define(SEND_INTERVAL, 2).

get_time() ->
  erlang:system_time(milli_seconds).

print_update(Cnt, Millis) ->
  io:format("Cnt: ~p Millis: ~p Interval: ~p~n", [Cnt, Millis, (Millis/(Cnt))]).

send_after() ->
  erlang:send_after(?SEND_INTERVAL, tc, check).

start() ->
  register(tc, spawn(?MODULE, loop, [0, get_time(), false])),
  send_after(),
  ok.

stop() ->
  tc ! stop,
  ok.

loop(Cnt, StartTime, Stop) ->
  receive
    check ->
      send_after(),
      if Stop orelse (((Cnt + 1) rem 40) =:= 0) ->
          print_update(Cnt+1, get_time() - StartTime);
        true -> true
      end,
      case Stop of
        true -> exit(stop);
        _ -> loop(Cnt+1, StartTime, false)
      end;
    stop ->
      loop(Cnt, StartTime, true);
    M ->
      io:format("Got ~p~n", [M]),
      loop(Cnt, StartTime, false)
  end.
