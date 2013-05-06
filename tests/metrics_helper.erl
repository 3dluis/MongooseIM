-module(metrics_helper).

-include_lib("common_test/include/ct.hrl").

-compile(export_all).

get_counter_value({_, _} = Counter) ->
    Result = rpc:call(ct:get_config(ejabberd_node),
                                          folsom_metrics,
                                          get_metric_value,
                                          [Counter]),
    case Result of
        [{count, Total}, {one, _}] ->
            {value, Total};
        Value when is_integer(Value) ->
            {value, Value};
        _ ->
            {error, uknonw_counter}
    end;
get_counter_value(CounterName) ->
    get_counter_value({ct:get_config(ejabberd_domain), CounterName}).


assert_counter(Value, CounterName) ->
    {value, Value} = get_counter_value(CounterName).