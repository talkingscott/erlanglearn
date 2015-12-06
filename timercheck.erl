-module(timercheck).
-export([loop/4,start/1,stop/0]).

get_time_millis() ->
  erlang:system_time(milli_seconds).

print_update(Cnt, Millis) ->
  io:format("Cnt: ~p Millis: ~p Interval: ~p~n", [Cnt, Millis, (Millis/(Cnt))]).

start(SendInterval) ->
  SendAfter = fun() -> erlang:send_after(SendInterval, tc, check) end,
  register(tc, spawn(?MODULE, loop, [SendAfter, 0, get_time_millis(), false])),
  SendAfter(),
  ok.

stop() ->
  tc ! stop,
  ok.

loop(SendAfter, Cnt, StartTime, Stop) ->
  receive
    check ->
      SendAfter(),
      if Stop orelse (((Cnt + 1) rem 40) =:= 0) ->
          print_update(Cnt+1, get_time_millis() - StartTime);
        true -> true
      end,
      case Stop of
        true -> exit(stop);
        _ -> loop(SendAfter, Cnt+1, StartTime, false)
      end;
    stop ->
      loop(SendAfter, Cnt, StartTime, true);
    M ->
      io:format("Got ~p~n", [M]),
      loop(SendAfter, Cnt, StartTime, false)
  end.
