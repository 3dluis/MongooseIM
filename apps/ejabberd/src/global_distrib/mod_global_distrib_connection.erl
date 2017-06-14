-module(mod_global_distrib_connection).

-behaviour(gen_server).

-include("ejabberd.hrl").
-include("jlib.hrl").

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).

%%--------------------------------------------------------------------
%% API
%%--------------------------------------------------------------------

init([Server]) ->
    {Addr, Port} = get_addr(Server),
    {ok, Socket} = gen_tcp:connect(Addr, Port, [binary, {active, false}]),
    {ok, TLSSocket} = fast_tls:tcp_to_tls(Socket, [connect | opt(tls_opts)]),
    fast_tls:setopts(TLSSocket, [{active, once}]),
    {ok, TLSSocket}.

handle_call({data, Data}, From, Socket) ->
    gen_server:reply(From, ok),
    handle_cast({data, Data}, Socket).

handle_cast({data, Data}, Socket) ->
    Annotated = <<(byte_size(Data)):32, Data/binary>>,
    ok = fast_tls:send(Socket, Annotated),
    {noreply, Socket}.

handle_info({tcp, _Socket, TLSData}, Socket) ->
    ok = fast_tls:setopts(Socket, [{active, once}]),
    fast_tls:recv_data(Socket, TLSData),
    {noreply, Socket};
handle_info({tcp_closed, _}, Socket) ->
    fast_tls:close(Socket),
    {stop, normal, Socket};
handle_info(_, Socket) ->
    {noreply, Socket}.

terminate(_Reason, _State) ->
    ignore.

opt(Key) ->
    mod_global_distrib_utils:opt(mod_global_distrib_sender, Key).

get_addr(Server) ->
    case ejabberd_config:get_local_option({global_distrib_addr, Server}) of
        undefined -> {unicode:characters_to_list(Server), opt(listen_port)};
        Other -> Other
    end.
