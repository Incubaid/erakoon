% This file is part of Erakoon, a distributed key-value store client.
%
% Copyright (C) 2012 Incubaid BVBA
%
% Licensees holding a valid Incubaid license may use this file in
% accordance with Incubaid's Arakoon commercial license agreement. For
% more information on how to enter into this agreement, please contact
% Incubaid (contact details can be found on www.arakoon.org/licensing).
%
% Alternatively, this file may be redistributed and/or modified under
% the terms of the GNU Affero General Public License version 3, as
% published by the Free Software Foundation. Under this license, this
% file is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
% FITNESS FOR A PARTICULAR PURPOSE.
%
% See the GNU Affero General Public License for more details.
% You should have received a copy of the
% GNU Affero General Public License along with this program (file "COPYING").
% If not, see <http://www.gnu.org/licenses/>.

-module(erakoon).
-behaviour(gen_server2).

-author("Nicolas Trangez <nicolas@incubaid.com>").
-version("Version: 0.1").

-define(SERVER, ?MODULE).
-define(TIMEOUT, 5000).
-define(TCP_OPTS, [
        binary, {packet, raw}, {nodelay, true}, {reuseaddr, true},
        {active, true}
]).

-define(ARA_CMD_MASK, 16#feed0000).

-define(ARA_CMD_HELLO, 16#0001).
-define(ARA_CMD_WHO_MASTER, 16#0002).
-define(ARA_CMD_EXISTS, 16#0007).
-define(ARA_CMD_GET, 16#0008).
-define(ARA_CMD_SET, 16#0009).
-define(ARA_CMD_DELETE, 16#000a).
-define(ARA_CMD_RANGE, 16#000b).
-define(ARA_CMD_PREFIX_KEYS, 16#000c).
-define(ARA_CMD_TEST_AND_SET, 16#000d).
-define(ARA_CMD_LAST_ENTRIES, 16#000e).
-define(ARA_CMD_RANGE_ENTRIES, 16#000f). % Typo in spec?
-define(ARA_CMD_SEQUENCE, 16#0010).


-define(ARA_RESULT_SUCCESS, 16#0000).
-define(ARA_RESULT_NO_MAGIC, 16#0001).
-define(ARA_RESULT_TOO_MANY_DEAD_NODES, 16#0002).
-define(ARA_RESULT_NO_HELLO, 16#0003).
-define(ARA_RESULT_NOT_MASTER, 16#0004).
-define(ARA_RESULT_NOT_FOUND, 16#0005).

-define(ARA_RESULT_UNKNOWN_FAILURE, 16#00ff).


% This is required to run the tests. No clue how to get around this...
-compile(export_all).


%% gen_server API
-export([
        connect/2, disconnect/0,

        hello/1, exists/1, set/2, get/1, delete/1, who_master/0
]).

%% gen_server callbacks
-export([
        init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2,
        code_change/3
]).


%% @doc execute hello command
hello(Message) ->
        gen_server2:call(?SERVER, {hello, {Message}}).

%% @doc execute exists command
exists(Key) ->
        gen_server2:call(?SERVER, {exists, {Key}}).

%% @doc execute set command
set(Key, Value) ->
        gen_server2:call(?SERVER, {set, {Key, Value}}).

%% @doc execute get command
get(Key) ->
        gen_server2:call(?SERVER, {get, {Key}}).

%% @doc execute delete command
delete(Key) ->
        gen_server2:call(?SERVER, {delete, {Key}}).

%% @doc execute who_master command
who_master() ->
        gen_server2:call(?SERVER, {who_master}).


%% @doc connect to Arakoon
connect(Host, Port) ->
        start_link(Host, Port).

%% @doc disconnect from Arakoon
disconnect() ->
        gen_server2:cast(?SERVER, stop).


%% @private
start_link(Host, Port) ->
        gen_server2:start_link({local, ?SERVER}, ?MODULE, [Host, Port], []).

%% @private
init([Host, Port]) ->
        case gen_tcp:connect(Host, Port, ?TCP_OPTS) of
                {ok, Socket} ->
                        Reply = send_cmd(Socket, ?ARA_CMD_WHO_MASTER, [],
                                get_option(fun get_string/2)),
                        case Reply of
                                {ok, none} ->
                                        gen_tcp:close(Socket),
                                        {error, master_unknown};
                                {ok, {some, _Master}} ->
                                        % TODO
                                        % Assume we need to connect to another
                                        % server
                                        gen_tcp:close(Socket),
                                        % But connect to the same one anyway
                                        gen_tcp:connect(Host, Port, ?TCP_OPTS);
                                Reply ->
                                        {error, Reply}
                        end;
                Other ->
                        Other
        end.


%% callbacks
handle_call({hello, {Message}}, _From, Socket) ->
        Reply = send_cmd(Socket, ?ARA_CMD_HELLO, [Message], fun get_string/2),
        {reply, Reply, Socket};

handle_call({exists, {Key}}, _From, Socket) ->
        Reply = send_cmd(Socket, ?ARA_CMD_EXISTS, [Key], fun get_bool/2),
        {reply, Reply, Socket};

handle_call({set, {Key, Value}}, _From, Socket) ->
        Reply = send_cmd(Socket, ?ARA_CMD_SET, [Key, Value], fun get_unit/2),
        {reply, Reply, Socket};

handle_call({get, {Key}}, _From, Socket) ->
        Reply = send_cmd(Socket, ?ARA_CMD_GET, [Key], fun get_binary/2),
        {reply, Reply, Socket};

handle_call({delete, {Key}}, _From, Socket) ->
        Reply = send_cmd(Socket, ?ARA_CMD_DELETE, [Key], fun get_unit/2),
        {reply, Reply, Socket};

handle_call({who_master}, _From, Socket) ->
        Reply = send_cmd(Socket, ?ARA_CMD_WHO_MASTER, [],
                    get_option(fun get_string/2)),
        {reply, Reply, Socket}.



handle_cast(stop, State) ->
        {stop, normal, State};

handle_cast(_Msg, State) ->
        {noreply, State}.


handle_info(_Info, State) ->
        {noreply, State}.


code_change(_OldVsn, State, _Extra) ->
        {ok, State}.


terminate(_Reason, Socket) ->
        gen_tcp:close(Socket),
        ok.


%% @private

value_to_bytes(Value) when is_boolean(Value) ->
        case Value of
                true -> <<1:8/little-unsigned>>;
                false -> <<0:8/little-unsigned>>
        end;

% TODO Can we assume this is 32bit?
value_to_bytes(Value) when is_integer(Value) ->
        <<Value:32/little-unsigned>>;

value_to_bytes(Value) when is_binary(Value) ->
        Len = size(Value),
        erlang:list_to_binary([<<Len:32/little-unsigned>>, Value]).


send_cmd(Socket, Cmd, Args, ResultHandler) ->
        Cmd2 = Cmd bxor ?ARA_CMD_MASK,

        AllValues = lists:append([Cmd2], Args),
        AllBinaries = lists:map(fun value_to_bytes/1, AllValues),
        Bytes = erlang:list_to_binary(AllBinaries),

        gen_tcp:send(Socket, Bytes),

        recv_reply(ResultHandler).

%% @private
recv_reply(ResultHandler) ->
        receive
                {tcp, Socket, Data} ->
                        parse_result(Socket, Data, ResultHandler);
                {error, closed} ->
                        connection_closed
                after ?TIMEOUT ->
                        timeout
        end.


parse_result(Socket, Data, ResultHandler) ->
        <<ResultCode:32/little-unsigned, Rest/binary>> = Data,

        case ResultCode of
                ?ARA_RESULT_SUCCESS ->
                        Result = ResultHandler(Socket, Rest),
                        case Result of
                                ok ->
                                        ok;
                                Other ->
                                        {ok, Other}
                        end;
                ?ARA_RESULT_NO_MAGIC ->
                        no_magic;
                ?ARA_RESULT_TOO_MANY_DEAD_NODES ->
                        too_many_dead_nodes;
                ?ARA_RESULT_NO_HELLO ->
                        no_hello;
                ?ARA_RESULT_NOT_MASTER ->
                        not_master;
                ?ARA_RESULT_NOT_FOUND ->
                        not_found;

                ?ARA_RESULT_UNKNOWN_FAILURE ->
                        unknown_failure
        end.

get_string(Socket, Data) ->
        <<Length:32/little-unsigned, Rest/binary>> = Data,
        ValueLength = size(Rest),

        Result = get_data(Socket, Rest, Length, ValueLength),
        binary_to_list(Result).

get_binary(Socket, Data) ->
        <<Length:32/little-unsigned, Rest/binary>> = Data,
        ValueLength = size(Rest),

        get_data(Socket, Rest, Length, ValueLength).

get_bool(Socket, Data) ->
        <<Value:8/little-unsigned>> = get_data(Socket, Data, 1, size(Data)),

        case Value of
                0 ->
                        false;
                1 ->
                        true
        end.

get_unit(_Socket, Data) ->
        0 = size(Data),
        ok.

get_option(Fun) ->
        Fun2 = fun(Socket, Data) ->
            <<HasValue:8/little, Rest/binary>> = Data,

            case HasValue of
                    0 ->
                            none;
                    1 ->
                            {some, Fun(Socket, Rest)}
            end
        end,

        Fun2.


get_data(Socket, Data, Length, Received) when Length < Received ->
        receive
                {tcp, Socket, NewData} ->
                        Combined = <<Data/binary, NewData/binary>>,
                        get_data(Socket, Combined, Length, size(Combined));
                {error, closed} ->
                        connection_closed
                after ?TIMEOUT ->
                        timeout
        end;

get_data(_, Data, Length, _) ->
        <<Bin:Length/binary>> = Data,
        Bin.
