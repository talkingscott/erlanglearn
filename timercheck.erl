-module(timercheck).
-export([loop/5,start/1,stop/0]).

get_time_millis() ->
  erlang:system_time(milli_seconds).

print_update(Cnt, Millis) ->
  io:format("Cnt: ~p Millis: ~p Interval: ~p~n", [Cnt, Millis, (Millis/(Cnt))]).

start(SendInterval) ->
  SendAfter = fun() ->
    erlang:send_after(SendInterval, tc, check)
  end,
  MaybePrintUpdate = fun(Cnt, Millis) ->
    % Would print once per second if the timer fired each SendInterval millis
    case Cnt rem erlang:trunc(1000 / SendInterval) of
      0 -> print_update(Cnt, Millis);
      _ -> true
    end
  end,
  register(tc, spawn(?MODULE, loop, [SendAfter, MaybePrintUpdate, 0, get_time_millis(), run])),
  SendAfter(),
  ok.

stop() ->
  tc ! stop,
  ok.

loop(SendAfter, MaybePrintUpdate, Cnt, StartTime, stop) ->
  receive
    check ->
      print_update(Cnt+1, get_time_millis() - StartTime),
      exit(stop);
    stop ->
      print_update(Cnt, get_time_millis() - StartTime),
      exit(double_stop);
    M ->
      io:format("Got ~p~n", [M]),
      loop(SendAfter, MaybePrintUpdate, Cnt, StartTime, stop)
  end;
loop(SendAfter, MaybePrintUpdate, Cnt, StartTime, run) ->
  receive
    check ->
      SendAfter(),
      MaybePrintUpdate(Cnt+1, get_time_millis() - StartTime),
      loop(SendAfter, MaybePrintUpdate, Cnt+1, StartTime, run);
    stop ->
      loop(SendAfter, MaybePrintUpdate, Cnt, StartTime, stop);
    M ->
      io:format("Got ~p~n", [M]),
      loop(SendAfter, MaybePrintUpdate, Cnt, StartTime, run)
  end.
