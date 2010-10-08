#!/usr/bin/env escript
%%! -pa ./ebin -sasl errlog_type error -boot start_sasl -noshell

main(_) ->
    etap:plan(8),

    etap:is(erakoon:parse_result(null, <<0:32/little, 3:32/little, "abc">>,
        fun erakoon:get_string/2), {ok, "abc"},
        "String results are decoded correctly"),
    etap:is(erakoon:parse_result(null, <<0:32/little>>,
        fun erakoon:get_unit/2), ok, "Unit result is encoded correctly"),

    etap:is(erakoon:parse_result(null, <<1:32/little>>, fun (_, _) -> ok end),
        no_magic, "No magic return code is decoded correctly"),
    etap:is(erakoon:parse_result(null, <<2:32/little>>, fun (_, _) -> ok end),
        too_many_dead_nodes,
        "Too many dead nodes return code is decoded correctly"),
    etap:is(erakoon:parse_result(null, <<3:32/little>>, fun (_, _) -> ok end),
        no_hello, "No hello return code is decoded correctly"),
    etap:is(erakoon:parse_result(null, <<4:32/little>>, fun (_, _) -> ok end),
        not_master, "Not master return code is decoded correctly"),
    etap:is(erakoon:parse_result(null, <<5:32/little>>, fun (_, _) -> ok end),
        not_found, "Not found return code is decoded correctly"),

    etap:is(erakoon:parse_result(null, <<16#ff:32/little>>,
        fun (_, _) -> ok end), unknown_failure,
        "Unknown failure return code is decoded correctly"),

    etap:end_tests().
