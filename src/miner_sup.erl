%%%-------------------------------------------------------------------
%% @doc miner Supervisor
%% @end
%%%-------------------------------------------------------------------
-module(miner_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SUP(I, Args), #{
    id => I,
    start => {I, start_link, Args},
    restart => permanent,
    shutdown => 5000,
    type => supervisor,
    modules => [I]
}).

-define(WORKER(I, Args), #{
    id => I,
    start => {I, start_link, Args},
    restart => permanent,
    shutdown => 5000,
    type => worker,
    modules => [I]
}).

%% ------------------------------------------------------------------
%% API functions
%% ------------------------------------------------------------------
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% ------------------------------------------------------------------
%% Supervisor callbacks
%% ------------------------------------------------------------------
init(_Args) ->
    SupFlags = #{
        strategy => rest_for_one,
        intensity => 2,
        period => 5
    },

    %% Blockchain Supervisor Options
    SeedNodes =
        case application:get_env(blockchain, seed_nodes) of
            {ok, ""} -> [];
            {ok, Seeds} -> string:split(Seeds, ",", all);
            _ -> []
        end,
    SeedNodeDNS = application:get_env(blockchain, seed_node_dns, []),
    % look up the DNS record and add any resulting addresses to the SeedNodes
    % no need to do any checks here as any bad combination results in an empty list
    SeedAddresses = string:tokens(lists:flatten([string:prefix(X, "blockchain-seed-nodes=") || [X] <- inet_res:lookup(SeedNodeDNS, in, txt), string:prefix(X, "blockchain-seed-nodes=") /= nomatch]), ","),
    Port = application:get_env(blockchain, port, 0),
    NumConsensusMembers = application:get_env(blockchain, num_consensus_members, 4),
    BaseDir = application:get_env(blockchain, base_dir, "data"),
    %% TODO: Remove when cuttlefish
    MaxInboundConnections = application:get_env(blockchain, max_inbound_connections, 10),

    %% downlink packets from state channels go here
    application:set_env(blockchain, sc_client_handler, miner_lora),

    case application:get_env(blockchain, key, undefined) of
        undefined ->
            #{ pubkey := PublicKey,
               ecdh_fun := ECDHFun,
               sig_fun := SigFun
             } = miner_keys:keys({file, BaseDir}),
            ECCWorker = [];
        {ecc, Props} when is_list(Props) ->
            #{ pubkey := PublicKey,
               key_slot := KeySlot,
               ecdh_fun := ECDHFun,
               sig_fun := SigFun
             } = miner_keys:keys({ecc, Props}),
            ECCWorker = [?WORKER(miner_ecc_worker, [KeySlot])];
        {PublicKey, ECDHFun, SigFun} ->
            ECCWorker = [],
            ok
    end,

    BlockchainOpts = [
        {key, {PublicKey, SigFun, ECDHFun}},
        {seed_nodes, SeedNodes ++ SeedAddresses},
        {max_inbound_connections, MaxInboundConnections},
        {port, Port},
        {num_consensus_members, NumConsensusMembers},
        {base_dir, BaseDir},
        {update_dir, application:get_env(miner, update_dir, undefined)},
        {group_delete_predicate, fun miner_consensus_mgr:group_predicate/1}
    ],

    %% Miner Options
    POCOpts = #{
        base_dir => BaseDir
    },

    OnionServer =
        case application:get_env(miner, radio_device, undefined) of
            {RadioBindIP, RadioBindPort, RadioSendIP, RadioSendPort} ->
                %% check if we are overriding domain checks ( for lora )
                %% If true then we expect default config data to be supplied, otherwise it defaults to undefined
                %% and will be set by miner lora based on geolocation data of the miners asserted location
                MaybeOverrideRegDomainChecks = application:get_env(miner, override_reg_domain_check, false),
                DefaultRegRegion = application:get_env(miner, default_reg_region, undefined),
                DefaultRegGeoZone = application:get_env(miner, default_reg_geo_zone, undefined),
                DefaultRegFreqList = application:get_env(miner, default_reg_freq_list, undefined),
                OnionOpts = #{
                    radio_udp_bind_ip => RadioBindIP,
                    radio_udp_bind_port => RadioBindPort,
                    radio_udp_send_ip => RadioSendIP,
                    radio_udp_send_port => RadioSendPort,
                    ecdh_fun => ECDHFun,
                    sig_fun => SigFun,
                    override_reg_domain_check => MaybeOverrideRegDomainChecks,
                    default_reg_region => DefaultRegRegion,
                    default_reg_geo_zone => DefaultRegGeoZone,
                    default_reg_freq_list => DefaultRegFreqList
                },
                [?WORKER(miner_onion_server, [OnionOpts]),
                 ?WORKER(miner_lora, [OnionOpts])];
            _ ->
                []
        end,

    EbusServer =
        case application:get_env(miner, use_ebus, false) of
            true -> [?WORKER(miner_ebus, [])];
            _ -> []
        end,

    ChildSpecs =
        ECCWorker++
        [
         ?SUP(blockchain_sup, [BlockchainOpts]),
         ?WORKER(miner_hbbft_sidecar, []),
         ?WORKER(miner, []),
         ?WORKER(miner_consensus_mgr, [ignored])
        ] ++
        EbusServer ++
        OnionServer ++
        [?WORKER(miner_poc_statem, [POCOpts])],
    {ok, {SupFlags, ChildSpecs}}.
