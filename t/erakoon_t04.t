#!/usr/bin/env escript
%%! -pa ./ebin -sasl errlog_type error -boot start_sasl -noshell

-define(ARAKOON_HOST, "localhost").
-define(ARAKOON_PORT, 4000).

-define(TEST_KEY, <<"test_key_1">>).
-define(TEST_VALUE, <<"test_value_1">>).
-define(TEST_VALUE2, <<"test_value_2">>).

main(_) ->
    etap:plan(17),

    etap:expect_fun(fun ({ok, _Pid}) -> true end,
        erakoon:connect(?ARAKOON_HOST, ?ARAKOON_PORT),
        "Connecting to Arakoon server"),

    etap:expect_fun(fun ({ok, _Version}) -> true end,
        erakoon:hello(<<"testsuite">>), "Sending hello"),

    {ok, KeyExists} = erakoon:exists(?TEST_KEY),
    Deleted = erakoon:delete(?TEST_KEY),
    case KeyExists of
        true ->
            etap:is(Deleted, ok, "Delete test key if it exists");
        false ->
            etap:is(Deleted, not_found, "Delete test key if it exists")
    end,

    etap:is(erakoon:exists(?TEST_KEY), {ok, false},
        "Checking whether the test key exists"),

    etap:is(erakoon:get(?TEST_KEY), not_found,
        "Check 'get' of non-existing key returns not_found"),

    etap:is(erakoon:set(?TEST_KEY, ?TEST_VALUE), ok,
        "Check 'set' returns ok"),
    etap:is(erakoon:get(?TEST_KEY), {ok, ?TEST_VALUE},
        "Check whether test value can be retrieved correctly"),

    etap:is(erakoon:delete(?TEST_KEY), ok,
        "Check whether test key deletion returns ok"),
    etap:is(erakoon:delete(?TEST_KEY), not_found,
        "Check whether consequent delete returns not_found"),
    etap:is(erakoon:get(?TEST_KEY), not_found,
        "Check whether a new get request returns not_found"),

    etap:is(erakoon:set(?TEST_KEY, ?TEST_VALUE), ok,
        "Check whether the test key can be set again"),
    etap:is(erakoon:get(?TEST_KEY), {ok, ?TEST_VALUE},
        "Check whether the key can be retrieved correctly"),
    etap:is(erakoon:set(?TEST_KEY, ?TEST_VALUE2), ok,
        "Check whether the key can be overwritten"),
    etap:is(erakoon:get(?TEST_KEY), {ok, ?TEST_VALUE2},
        "Check whether the new value can be retrieved"),

    etap:is(erakoon:delete(?TEST_KEY), ok, "Check whether deletion works"),
    etap:is(erakoon:get(?TEST_KEY), not_found,
        "Check whether one more get request returns not_found"),

    etap:expect_fun(fun ({ok, {some, _MasterName}}) -> true end,
        erakoon:who_master(), "Check whether a 'who_master' call works"),

    etap:end_tests().
