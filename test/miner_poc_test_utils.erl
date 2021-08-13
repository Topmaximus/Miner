-module(miner_poc_test_utils).

-include("miner_poc_v11_vars.hrl").
-export([send_receipts/2, poc_v11_vars/0]).

send_receipts(LatLongs, Challengees) ->
    lists:foreach(
        fun({_LatLong, {PrivKey, PubKey}}) ->
            Address = libp2p_crypto:pubkey_to_bin(PubKey),
            SigFun = libp2p_crypto:mk_sig_fun(PrivKey),
            {Mega, Sec, Micro} = os:timestamp(),
            Timestamp = Mega * 1000000 * 1000000 + Sec * 1000000 + Micro,
            case lists:keyfind(Address, 1, Challengees) of
                {Address, LayerData} ->
                    Receipt = blockchain_poc_receipt_v1:new(Address, Timestamp, 0, LayerData, radio),
                    SignedReceipt = blockchain_poc_receipt_v1:sign(Receipt, SigFun),
                    miner_poc_statem:receipt(make_ref(), SignedReceipt, "/ip4/127.0.0.1/tcp/1234");
                _ ->
                    ok
            end
        end,
        LatLongs
    ).

%% Below is lifted from blockchain-core tests...
poc_v11_vars() ->
    RegionURLs = region_urls(),
    Regions = download_regions(RegionURLs),
    V0 = maps:put(regulatory_regions, ?regulatory_region_bin_str, maps:from_list(Regions)),
    V1 = #{
           poc_version => 11,
           %% XXX: 1.0 = no loss? because the mic_rcv_sig calculation multiplies this? unclear...
           fspl_loss => 1.0,
           %% NOTE: Set to 3 to attach tx_power to poc receipt
           data_aggregation_version => 3,
           region_us915_params => region_params_us915(),
           region_eu868_params => region_params_eu868(),
           region_au915_params => region_params_au915(),
           region_as923_1_params => region_params_as923_1(),
           region_as923_2_params => region_params_as923_2(),
           region_as923_3_params => region_params_as923_3(),
           region_as923_4_params => region_params_as923_4(),
           region_ru864_params => region_params_ru864(),
           region_cn470_params => region_params_cn470(),
           region_in865_params => region_params_in865(),
           region_kr920_params => region_params_kr920(),
           region_eu433_params => region_params_eu433()
          },
    maps:merge(V0, V1).

region_urls() ->
    [
        {region_as923_1, ?region_as923_1_url},
        {region_as923_2, ?region_as923_2_url},
        {region_as923_3, ?region_as923_3_url},
        {region_as923_4, ?region_as923_4_url},
        {region_au915, ?region_au915_url},
        {region_cn470, ?region_cn470_url},
        {region_eu433, ?region_eu433_url},
        {region_eu868, ?region_eu868_url},
        {region_in865, ?region_in865_url},
        {region_kr920, ?region_kr920_url},
        {region_ru864, ?region_ru864_url},
        {region_us915, ?region_us915_url}
    ].

download_regions(RegionURLs) ->
    miner_ct_utils:pmap(
        fun({Region, URL}) ->
            Ser = download_serialized_region(URL),
            {Region, Ser}
        end,
        RegionURLs
    ).

region_params_us915() ->
    <<10, 41, 8, 160, 144, 215, 175, 3, 16, 200, 208, 7, 24, 232, 2, 34, 26, 10, 4, 8, 4, 16, 25,
        10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 41, 8, 224, 245,
        202, 175, 3, 16, 200, 208, 7, 24, 232, 2, 34, 26, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67,
        10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 41, 8, 160, 219, 190, 175, 3, 16, 200,
        208, 7, 24, 232, 2, 34, 26, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139,
        1, 10, 5, 8, 1, 16, 128, 2, 10, 41, 8, 224, 192, 178, 175, 3, 16, 200, 208, 7, 24, 232, 2,
        34, 26, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16,
        128, 2, 10, 41, 8, 160, 166, 166, 175, 3, 16, 200, 208, 7, 24, 232, 2, 34, 26, 10, 4, 8, 4,
        16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 41, 8,
        224, 139, 154, 175, 3, 16, 200, 208, 7, 24, 232, 2, 34, 26, 10, 4, 8, 4, 16, 25, 10, 4, 8,
        3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 41, 8, 160, 241, 141, 175,
        3, 16, 200, 208, 7, 24, 232, 2, 34, 26, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8,
        2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 41, 8, 224, 214, 129, 175, 3, 16, 200, 208, 7,
        24, 232, 2, 34, 26, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10,
        5, 8, 1, 16, 128, 2>>.

region_params_eu868() ->
    <<10, 35, 8, 224, 180, 236, 157, 3, 16, 200, 208, 7, 24, 140, 1, 34, 20, 10, 4, 8, 6, 16, 65,
        10, 5, 8, 3, 16, 129, 1, 10, 5, 8, 2, 16, 238, 1, 10, 35, 8, 160, 154, 224, 157, 3, 16, 200,
        208, 7, 24, 140, 1, 34, 20, 10, 4, 8, 6, 16, 65, 10, 5, 8, 3, 16, 129, 1, 10, 5, 8, 2, 16,
        238, 1, 10, 35, 8, 224, 255, 211, 157, 3, 16, 200, 208, 7, 24, 140, 1, 34, 20, 10, 4, 8, 6,
        16, 65, 10, 5, 8, 3, 16, 129, 1, 10, 5, 8, 2, 16, 238, 1, 10, 35, 8, 160, 229, 199, 157, 3,
        16, 200, 208, 7, 24, 140, 1, 34, 20, 10, 4, 8, 6, 16, 65, 10, 5, 8, 3, 16, 129, 1, 10, 5, 8,
        2, 16, 238, 1, 10, 35, 8, 224, 202, 187, 157, 3, 16, 200, 208, 7, 24, 140, 1, 34, 20, 10, 4,
        8, 6, 16, 65, 10, 5, 8, 3, 16, 129, 1, 10, 5, 8, 2, 16, 238, 1, 10, 35, 8, 160, 132, 145,
        158, 3, 16, 200, 208, 7, 24, 140, 1, 34, 20, 10, 4, 8, 6, 16, 65, 10, 5, 8, 3, 16, 129, 1,
        10, 5, 8, 2, 16, 238, 1, 10, 35, 8, 160, 132, 145, 158, 3, 16, 200, 208, 7, 24, 140, 1, 34,
        20, 10, 4, 8, 6, 16, 65, 10, 5, 8, 3, 16, 129, 1, 10, 5, 8, 2, 16, 238, 1, 10, 35, 8, 224,
        233, 132, 158, 3, 16, 200, 208, 7, 24, 140, 1, 34, 20, 10, 4, 8, 6, 16, 65, 10, 5, 8, 3, 16,
        129, 1, 10, 5, 8, 2, 16, 238, 1, 10, 35, 8, 160, 207, 248, 157, 3, 16, 200, 208, 7, 24, 140,
        1, 34, 20, 10, 4, 8, 6, 16, 65, 10, 5, 8, 3, 16, 129, 1, 10, 5, 8, 2, 16, 238, 1>>.

region_params_au915() ->
    <<10, 53, 8, 192, 189, 234, 181, 3, 16, 200, 208, 7, 24, 172, 2, 34, 38, 10, 4, 8, 6, 16, 25,
        10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10,
        5, 8, 1, 16, 128, 2, 10, 53, 8, 128, 163, 222, 181, 3, 16, 200, 208, 7, 24, 172, 2, 34, 38,
        10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5,
        8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 53, 8, 192, 136, 210, 181, 3, 16, 200, 208,
        7, 24, 172, 2, 34, 38, 10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4,
        8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 53, 8, 128, 238, 197,
        181, 3, 16, 200, 208, 7, 24, 172, 2, 34, 38, 10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10,
        4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10,
        53, 8, 192, 211, 185, 181, 3, 16, 200, 208, 7, 24, 172, 2, 34, 38, 10, 4, 8, 6, 16, 25, 10,
        4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5,
        8, 1, 16, 128, 2, 10, 53, 8, 128, 185, 173, 181, 3, 16, 200, 208, 7, 24, 172, 2, 34, 38, 10,
        4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2,
        16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 53, 8, 192, 158, 161, 181, 3, 16, 200, 208, 7, 24,
        172, 2, 34, 38, 10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3,
        16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 53, 8, 128, 132, 149, 181, 3,
        16, 200, 208, 7, 24, 172, 2, 34, 38, 10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4,
        16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2>>.

region_params_as923_1() ->
    <<10, 53, 8, 128, 181, 210, 183, 3, 16, 200, 208, 7, 24, 160, 1, 34, 38, 10, 4, 8, 6, 16, 25,
        10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10,
        5, 8, 1, 16, 128, 2, 10, 53, 8, 192, 185, 143, 184, 3, 16, 200, 208, 7, 24, 160, 1, 34, 38,
        10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5,
        8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 53, 8, 128, 159, 131, 184, 3, 16, 200, 208,
        7, 24, 160, 1, 34, 38, 10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4,
        8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 53, 8, 192, 132, 247,
        183, 3, 16, 200, 208, 7, 24, 160, 1, 34, 38, 10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10,
        4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10,
        53, 8, 128, 234, 234, 183, 3, 16, 200, 208, 7, 24, 160, 1, 34, 38, 10, 4, 8, 6, 16, 25, 10,
        4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5,
        8, 1, 16, 128, 2, 10, 53, 8, 192, 207, 222, 183, 3, 16, 200, 208, 7, 24, 160, 1, 34, 38, 10,
        4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2,
        16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 53, 8, 192, 238, 167, 184, 3, 16, 200, 208, 7, 24,
        160, 1, 34, 38, 10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3,
        16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 53, 8, 128, 212, 155, 184, 3,
        16, 200, 208, 7, 24, 160, 1, 34, 38, 10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4,
        16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2>>.

region_params_as923_2() ->
    <<10, 53, 8, 192, 141, 241, 184, 3, 16, 200, 208, 7, 24, 160, 1, 34, 38, 10, 4, 8, 6, 16, 25,
        10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10,
        5, 8, 1, 16, 128, 2, 10, 53, 8, 128, 243, 228, 184, 3, 16, 200, 208, 7, 24, 160, 1, 34, 38,
        10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5,
        8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 53, 8, 192, 216, 216, 184, 3, 16, 200, 208,
        7, 24, 160, 1, 34, 38, 10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4,
        8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 53, 8, 128, 190, 204,
        184, 3, 16, 200, 208, 7, 24, 160, 1, 34, 38, 10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10,
        4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10,
        53, 8, 192, 163, 192, 184, 3, 16, 200, 208, 7, 24, 160, 1, 34, 38, 10, 4, 8, 6, 16, 25, 10,
        4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5,
        8, 1, 16, 128, 2, 10, 53, 8, 128, 137, 180, 184, 3, 16, 200, 208, 7, 24, 160, 1, 34, 38, 10,
        4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2,
        16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 53, 8, 192, 238, 167, 184, 3, 16, 200, 208, 7, 24,
        160, 1, 34, 38, 10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3,
        16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 53, 8, 128, 212, 155, 184, 3,
        16, 200, 208, 7, 24, 160, 1, 34, 38, 10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4,
        16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2>>.

region_params_as923_3() ->
    <<10, 53, 8, 128, 132, 149, 181, 3, 16, 200, 208, 7, 24, 160, 1, 34, 38, 10, 4, 8, 6, 16, 25,
        10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10,
        5, 8, 1, 16, 128, 2, 10, 53, 8, 192, 233, 136, 181, 3, 16, 200, 208, 7, 24, 160, 1, 34, 38,
        10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5,
        8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2>>.

region_params_as923_4() ->
    <<10, 53, 8, 224, 224, 191, 181, 3, 16, 200, 208, 7, 24, 160, 1, 34, 38, 10, 4, 8, 6, 16, 25,
        10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10,
        5, 8, 1, 16, 128, 2, 10, 53, 8, 160, 198, 179, 181, 3, 16, 200, 208, 7, 24, 160, 1, 34, 38,
        10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5,
        8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2>>.

region_params_ru864() ->
    <<10, 53, 8, 224, 211, 181, 158, 3, 16, 200, 208, 7, 24, 160, 1, 34, 38, 10, 4, 8, 6, 16, 25,
        10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10,
        5, 8, 1, 16, 128, 2, 10, 53, 8, 160, 185, 169, 158, 3, 16, 200, 208, 7, 24, 160, 1, 34, 38,
        10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5,
        8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2>>.

region_params_cn470() ->
    <<10, 53, 8, 160, 236, 198, 232, 1, 16, 200, 208, 7, 24, 191, 1, 34, 38, 10, 4, 8, 6, 16, 25,
        10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10,
        5, 8, 1, 16, 128, 2, 10, 53, 8, 224, 209, 186, 232, 1, 16, 200, 208, 7, 24, 191, 1, 34, 38,
        10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5,
        8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 53, 8, 160, 183, 174, 232, 1, 16, 200, 208,
        7, 24, 191, 1, 34, 38, 10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4,
        8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 53, 8, 224, 156, 162,
        232, 1, 16, 200, 208, 7, 24, 191, 1, 34, 38, 10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10,
        4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10,
        53, 8, 160, 130, 150, 232, 1, 16, 200, 208, 7, 24, 191, 1, 34, 38, 10, 4, 8, 6, 16, 25, 10,
        4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5,
        8, 1, 16, 128, 2, 10, 53, 8, 224, 231, 137, 232, 1, 16, 200, 208, 7, 24, 191, 1, 34, 38, 10,
        4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2,
        16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 53, 8, 160, 205, 253, 231, 1, 16, 200, 208, 7, 24,
        191, 1, 34, 38, 10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3,
        16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 53, 8, 224, 178, 241, 231, 1,
        16, 200, 208, 7, 24, 191, 1, 34, 38, 10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4,
        16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2>>.

region_params_in865() ->
    <<10, 53, 8, 132, 253, 211, 156, 3, 16, 200, 208, 7, 24, 172, 2, 34, 38, 10, 4, 8, 6, 16, 25,
        10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10,
        5, 8, 1, 16, 128, 2, 10, 53, 8, 232, 195, 247, 156, 3, 16, 200, 208, 7, 24, 172, 2, 34, 38,
        10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5,
        8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 53, 8, 228, 156, 191, 156, 3, 16, 200, 208,
        7, 24, 172, 2, 34, 38, 10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4,
        8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2>>.

region_params_kr920() ->
    <<10, 53, 8, 160, 225, 161, 184, 3, 16, 200, 208, 7, 24, 140, 1, 34, 38, 10, 4, 8, 6, 16, 25,
        10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10,
        5, 8, 1, 16, 128, 2, 10, 53, 8, 224, 198, 149, 184, 3, 16, 200, 208, 7, 24, 140, 1, 34, 38,
        10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5,
        8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 53, 8, 160, 172, 137, 184, 3, 16, 200, 208,
        7, 24, 140, 1, 34, 38, 10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4,
        8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 53, 8, 224, 145, 253,
        183, 3, 16, 200, 208, 7, 24, 140, 1, 34, 38, 10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10,
        4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10,
        53, 8, 160, 247, 240, 183, 3, 16, 200, 208, 7, 24, 140, 1, 34, 38, 10, 4, 8, 6, 16, 25, 10,
        4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5,
        8, 1, 16, 128, 2, 10, 53, 8, 224, 220, 228, 183, 3, 16, 200, 208, 7, 24, 140, 1, 34, 38, 10,
        4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2,
        16, 139, 1, 10, 5, 8, 1, 16, 128, 2, 10, 53, 8, 160, 194, 216, 183, 3, 16, 200, 208, 7, 24,
        140, 1, 34, 38, 10, 4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3,
        16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1, 16, 128, 2>>.

region_params_eu433() ->
    <<10, 51, 8, 188, 170, 214, 20, 16, 200, 208, 7, 24, 121, 34, 38, 10, 4, 8, 6, 16, 25, 10, 4, 8,
        5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1, 10, 5, 8, 1,
        16, 128, 2, 10, 51, 8, 156, 142, 213, 20, 16, 200, 208, 7, 24, 121, 34, 38, 10, 4, 8, 6, 16,
        25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2, 16, 139, 1,
        10, 5, 8, 1, 16, 128, 2, 10, 51, 8, 252, 241, 211, 20, 16, 200, 208, 7, 24, 121, 34, 38, 10,
        4, 8, 6, 16, 25, 10, 4, 8, 5, 16, 25, 10, 4, 8, 4, 16, 25, 10, 4, 8, 3, 16, 67, 10, 5, 8, 2,
        16, 139, 1, 10, 5, 8, 1, 16, 128, 2>>.

download_serialized_region(URL) ->
    %% Example URL: "https://github.com/JayKickliter/lorawan-h3-regions/blob/main/serialized/US915.res7.h3idx?raw=true"
    {ok, Dir} = file:get_cwd(),
    %% Ensure priv dir exists
    PrivDir = filename:join([Dir, "priv"]),
    ok = filelib:ensure_dir(PrivDir ++ "/"),
    ok = ssl:start(),
    {ok, {{_, 200, "OK"}, _, Body}} = httpc:request(URL),
    FName = hd(string:tokens(hd(lists:reverse(string:tokens(URL, "/"))), "?")),
    FPath = filename:join([PrivDir, FName]),
    ok = file:write_file(FPath, Body),
    {ok, Data} = file:read_file(FPath),
    Data.
