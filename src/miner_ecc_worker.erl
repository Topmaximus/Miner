-module(miner_ecc_worker).

-behavior(gen_server).

-export([sign/1,
         ecdh/1]).

-export([start_link/1,
         init/1,
         handle_call/3,
         handle_cast/2,
         terminate/2]).

-record(state, {
                ecc_handle :: pid(),
                key_slot :: non_neg_integer()
               }).

-spec sign(binary()) -> {ok, Signature::binary()} | {error, term()}.
sign(Binary) ->
    gen_server:call(?MODULE, {sign, Binary}).

-spec ecdh(libp2p_crypto:pubkey()) -> {ok, Preseed::binary()} | {error, term()}.
ecdh({ecc_compact, PubKey}) ->
    gen_server:call(?MODULE, {ecdh, PubKey}).

start_link(KeySlot) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [KeySlot], []).


init([KeySlot]) ->
    {ok, ECCHandle} = ecc508:start_link(),
    {ok, #state{ecc_handle=ECCHandle, key_slot=KeySlot}}.


handle_call({sign, Binary}, _From, State=#state{ecc_handle=Pid}) ->
    ecc508:wake(Pid),
    Reply = ecc508:sign(Pid, State#state.key_slot, Binary),
    ecc508:sleep(Pid),
    {reply, Reply, State};
handle_call({ecdh, PubKey}, _From, State=#state{ecc_handle=Pid}) ->
    ecc508:wake(Pid),
    Reply = ecc508:ecdh(Pid, State#state.key_slot, PubKey),
    ecc508:sleep(Pid),
    {reply, Reply, State};

handle_call(_Msg, _From, State) ->
    lager:warning("unhandled call ~p", [_Msg]),
    {reply, ok, State}.


handle_cast(_Msg, State) ->
    lager:warning("unhandled cast ~p", [_Msg]),
    {noreply, State}.

terminate(_Reason, State=#state{}) ->
    catch ecc508:stop(State#state.ecc_handle).
