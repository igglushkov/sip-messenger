-module(uri_tools_tests).

-include_lib("eunit/include/eunit.hrl").
-include_lib("nklib/include/nklib.hrl").


get_user_uri_test() ->
    SipUri = #uri{scheme = sip, user = <<"3004">>, domain = <<"127.0.0.1">>, port = 5065},

    UserUri = uri_tools:get_user_uri(SipUri),

    ?assertEqual(<<"sip:3004@127.0.0.1:5065">>, UserUri).


build_user_uri_test() ->
    {Scheme, User, Domain} = {sip, <<"3004">>, <<"127.0.0.1">>},

    UserUri = uri_tools:build_user_uri(Scheme, User, Domain),

    ?assertEqual(<<"sip:3004@127.0.0.1">>, UserUri).
