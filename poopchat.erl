-module(poopchat).
-compile(export_all).

start_server(Port) ->
  Pid = spawn_link(fun() ->
    {ok, ListenSocket} = gen_tcp:listen(Port, [binary, {active, false}]),
    spawn(fun() -> acceptor(ListenSocket, []) end),
    timer:sleep(infinity)
  end),
  {ok, Pid}.

acceptor(ListenSocket, []) ->
  {ok, Socket} = gen_tcp:accept(ListenSocket),
  Handler_Pid = spawn(?MODULE, handle, [Socket]),
  ok = gen_tcp:controlling_process(Socket, Handler_Pid),
  spawn(fun() -> acceptor(ListenSocket, [Handler_Pid]) end);
acceptor(ListenSocket, [FirstSocket | Rest]) ->
  {ok, Socket} = gen_tcp:accept(ListenSocket),
  Handler_Pid = spawn(?MODULE, handle, [Socket, FirstSocket]),
  ok = gen_tcp:controlling_process(Socket, Handler_Pid),
  FirstSocket ! {ping, Handler_Pid, "Found someone to chat with"},
  spawn(fun() -> acceptor(ListenSocket, []) end).

handle(Socket) ->
  inet:setopts(Socket, [{active, true}]),
  receive
    {ping, Ping_Pid, Msg} ->
      gen_tcp:send(Socket, Msg),
      handle(Socket, Ping_Pid);
    {tcp, Socket, <<"quit", _/binary>>} ->
      gen_tcp:close(Socket);
    {tcp, Socket, Msg} ->
      gen_tcp:send(Socket, Msg),
    handle(Socket)
  end.

handle(Socket, Pid) ->
  inet:setopts(Socket, [{active, true}]),
  receive
    {ping, Ping_Pid, Msg} ->
      gen_tcp:send(Socket, Msg),
      handle(Socket, Pid);
    {tcp, Socket, <<"quit", _/binary>>} ->
      gen_tcp:close(Socket);
    {tcp, Socket, Msg} ->
      gen_tcp:send(Socket, Msg),
      Pid ! {ping, self(), Msg},
    handle(Socket, Pid)
  end.