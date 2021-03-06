-module(dalmatiner_opt).

-define(WEEK, 604800). %% Seconds in a week.

-export([resolution/1, set_resolution/2,
         lifetime/1, set_lifetime/2,
         ppf/1, set_ppf/2,
         grace/1, set_grace/2,
         delete/1]).
-ignore_xref([set_resolution/2]).

resolution(Bucket) when is_binary(Bucket) ->
    get(<<"buckets">>, <<"resolution">>, Bucket, {metric_vnode, resolution},
        1000).

set_resolution(Bucket, Resolution)
  when is_binary(Bucket),
       is_integer(Resolution),
       Resolution > 0 ->
    set(<<"buckets">>, <<"resolution">>, Bucket, Resolution).

delete_resolution(Bucket) when is_binary(Bucket) ->
    riak_core_metadata:delete({<<"buckets">>, <<"resolution">>}, Bucket).

lifetime(Bucket) when is_binary(Bucket) ->
    get(<<"buckets">>, <<"lifetime">>, Bucket, {metric_vnode, lifetime},
        infinity).

set_lifetime(Bucket, TTL) when is_binary(Bucket), is_integer(TTL), TTL > 0 ->
    set(<<"buckets">>, <<"lifetime">>, Bucket, TTL);
set_lifetime(Bucket, infinity) when is_binary(Bucket) ->
    set(<<"buckets">>, <<"lifetime">>, Bucket, infinity).

delete_lifetime(Bucket) when is_binary(Bucket) ->
    riak_core_metadata:delete({<<"buckets">>, <<"lifetime">>}, Bucket).

set_ppf(Bucket, PPF) ->
    set(<<"buckets">>, <<"points_per_file">>, Bucket, PPF).

ppf(Bucket) when is_binary(Bucket) ->
    ppf(Bucket, ?WEEK).

ppf(Bucket, Dflt) when is_binary(Bucket) ->
    get(<<"buckets">>, <<"points_per_file">>, Bucket,
        {metric_vnode, points_per_file}, Dflt).
delete_ppf(Bucket) when is_binary(Bucket) ->
    riak_core_metadata:delete({<<"buckets">>, <<"points_per_file">>}, Bucket).

set_grace(Bucket, GRACE) ->
    set(<<"buckets">>, <<"grace">>, Bucket, GRACE).

grace(Bucket) when is_binary(Bucket) ->
    grace(Bucket, 0).

grace(Bucket, Dflt) when is_binary(Bucket) ->
    get(<<"buckets">>, <<"grace">>, Bucket,
        {metric_vnode, grace}, Dflt).

delete_grace(Bucket) when is_binary(Bucket) ->
    riak_core_metadata:delete({<<"buckets">>, <<"grace">>}, Bucket).

delete(Bucket) ->
    delete_ppf(Bucket),
    delete_lifetime(Bucket),
    delete_grace(Bucket),
    delete_resolution(Bucket).

%%%===================================================================
%%% Internal Functions
%%%===================================================================

get(Prefix, SubPrefix, Key, {EnvApp, EnvKey}, Dflt) ->
    case riak_core_metadata:get({Prefix, SubPrefix}, Key) of
        undefined ->
            V = get_dflt(Prefix, SubPrefix, Key, {EnvApp, EnvKey}, Dflt),
            set(Prefix, SubPrefix, Key, V),
            V;
        V ->
            V
    end.

get_dflt(Prefix, SubPrefix, Key, {EnvApp, EnvKey}, Dflt) ->
    %% This is hacky but some data was stored in reverse order
    %% before.
    case riak_core_metadata:get({Prefix, Key}, SubPrefix) of
        undefined ->
            case application:get_env(EnvApp, EnvKey) of
                {ok, Val} ->
                    Val;
                undefined ->
                    Dflt
            end;
        V ->
            riak_core_metadata:delete({Prefix, Key}, SubPrefix),
            V
    end.


set(Prefix, SubPrefix, Key, Val) ->
    riak_core_metadata:put({Prefix, SubPrefix}, Key, Val).
