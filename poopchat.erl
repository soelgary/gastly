-module(poopchat).
-compile(export_all).

start_server(Port) ->
  % starts the tcp server and waits for the next connection
  Pid = spawn_link(fun() ->
    {ok, ListenSocket} = gen_tcp:listen(Port, [binary, {active, false}]),
    spawn(fun() -> acceptor(ListenSocket, []) end),
    timer:sleep(infinity)
  end),
  {ok, Pid}.

acceptor(ListenSocket, []) ->
  % Waits to accept the next pooper. This pooper is the first in the
  % queue to connect with someone
  {ok, Socket} = gen_tcp:accept(ListenSocket),
  Handler_Pid = spawn(?MODULE, handle, [Socket]),
  ok = gen_tcp:controlling_process(Socket, Handler_Pid),
  spawn(fun() -> acceptor(ListenSocket, [Handler_Pid]) end);
acceptor(ListenSocket, [FirstSocket | Rest]) ->
  % Waits to accept the next pooper. This pooper will automatically
  % connect with the first pooper in the queue
  {ok, Socket} = gen_tcp:accept(ListenSocket),
  Handler_Pid = spawn(?MODULE, handle, [Socket, FirstSocket]),
  ok = gen_tcp:controlling_process(Socket, Handler_Pid),
  FirstSocket ! {found_pooper, Handler_Pid},
  spawn(fun() -> acceptor(ListenSocket, []) end).

handle(Socket) ->
  % Socket(pooper) is not connected with anyone
  inet:setopts(Socket, [{active, true}]),
  receive
    {found_pooper, Pooper_Pid} ->
      handle(Socket, Pooper_Pid);
    {tcp, Socket, <<"quit", _/binary>>} ->
      gen_tcp:close(Socket);
    {tcp, Socket, Msg} ->
      gen_tcp:send(Socket, Msg),
    handle(Socket)
  end;
handle(Socket, Pid) ->
  % Socket(pooper) is connected to pooper with process id, Pid
  inet:setopts(Socket, [{active, true}]),
  receive
    {send, Msg} ->
      gen_tcp:send(Socket, Msg),
      handle(Socket, Pid);
    {tcp, Socket, <<"quit", _/binary>>} ->
      gen_tcp:close(Socket);
    {tcp, Socket, Msg} ->
      send_message(self(), Pid, Msg),
    handle(Socket, Pid)
  end.

send_message(Pid1, Pid2, Msg) ->
  Actual_Msg = Msg,
  Pid1 ! {send, Actual_Msg},
  Pid2 ! {send, Actual_Msg}.

