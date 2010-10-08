#!/usr/bin/env escript
%%! -pa ./ebin -sasl errlog_type error -boot start_sasl -noshell

main(_) ->
    etap:plan(7),

    % Booleans
    etap:is(erakoon:value_to_bytes(true), <<1:8/little>>,
        "Boolean true is encoded correctly"),
    etap:is(erakoon:value_to_bytes(false), <<0:8/little>>,
        "Boolean false is encoded correctly"),

    % Binaries
    etap:is(erakoon:value_to_bytes(<< >>), <<0:32/little>>,
        "Empty binary is encoded correctly"),
    etap:is(erakoon:value_to_bytes(<<"abc">>), <<3:32/little, "abc">>,
        "Binary \"abc\" is encoded correctly"),

    % Integers
    etap:is(erakoon:value_to_bytes(0), <<0:32/little>>,
        "Int32 0 is encoded correctly"),
    etap:is(erakoon:value_to_bytes(1), <<1:32/little>>,
        "Int32 1 is encoded correctlyu"),
    etap:is(erakoon:value_to_bytes(-1), <<-1:32/little>>,
        "Int32 -1 is encoded correctly"),

    etap:end_tests().
