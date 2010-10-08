#!/usr/bin/env escript
%%! -pa ./ebin -sasl errlog_type error -boot start_sasl -noshell

main(_) ->
    etap:plan(14),

    etap:is(erakoon:get_bool(null, <<0:8/little>>), false,
        "Boolean false is decoded correctly"),
    etap:is(erakoon:get_bool(null, <<1:8/little>>), true,
        "Boolean true is decoded correctly"),

    etap:is(erakoon:get_bool(null, erakoon:value_to_bytes(false)), false,
        "Boolean false encoding/decoding is reversible"),
    etap:is(erakoon:get_bool(null, erakoon:value_to_bytes(true)), true,
        "Boolean true encoding/decoding is reversible"),

    etap:is(erakoon:get_string(null, <<0:32/little>>), "",
        "Empty string is decoded correctly"),
    etap:is(erakoon:get_string(null, <<1:32/little, "a">>), "a",
        "Single-character string is decoded correctly"),
    etap:is(erakoon:get_string(null, <<3:32/little, "abc">>), "abc",
        "String is decoded correctly"),

    etap:is(erakoon:get_string(null, erakoon:value_to_bytes(<<"">>)), "",
        "Empty string encoding/decoding is reversible"),
    etap:is(erakoon:get_string(null, erakoon:value_to_bytes(<<"abc">>)),
        "abc", "String encoding/decoding is reversible"),

    etap:is(erakoon:get_binary(null, erakoon:value_to_bytes(<<"">>)), << >>,
        "Empty binary encoding/decoding is reversible"),
    etap:is(erakoon:get_binary(null, erakoon:value_to_bytes(<<"abc">>)),
        <<"abc">>, "Binary encoding/decoding is reversible"),

    etap:is(erakoon:get_unit(null, << >>), ok,
        "Unit is decoded correctly"),

    OptionString = erakoon:get_option(fun erakoon:get_string/2),
    etap:is(OptionString(null, <<0:8/little>>), none,
        "None is decoded correctly"),
    etap:is(OptionString(null, <<1:8/little, 3:32/little, "abc">>),
        {some, "abc"}, "Some String is decoded correctly"),

    etap:end_tests().
