-module(concurrent_dict_ffi).

-export([
    create_table/1,
    lookup/2
]).

create_table(Name) when is_atom(Name) ->
    ets:new(Name, [set, named_table, public, {read_concurrency, true}, {write_concurrency, true}]).

lookup(TableId, Index) ->
    case ets:lookup_element(TableId, Index, 2, error) of
        error -> {error, nil};
        Record -> {ok, Record}
    end.
