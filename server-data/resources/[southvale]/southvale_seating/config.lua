Config = {
    -- Common bench/chair/stool prop models found across the default GTA V map.
    -- Missing/renamed models simply never match ox_target's model filter, so
    -- an incorrect entry here is harmless rather than breaking.
    models = {
        `prop_bench_01a`, `prop_bench_01b`, `prop_bench_03`, `prop_bench_04`,
        `prop_bench_05`, `prop_bench_06`, `prop_bench_07`,
        `prop_wood_chair01a`, `prop_chair_01a`, `prop_chair_03`, `prop_chair_04`,
        `prop_stool_01`, `prop_step_stool_01`, `v_ind_cfbarstool`,
        `ex_prop_table_chair_01`, `prop_dining_chair`,
    },

    scenario = 'PROP_HUMAN_SEAT_CHAIR',
    interactDistance = 1.5,
    -- Slight lift so the ped doesn't clip through the seat mesh; scenario
    -- alignment does the rest (this is the same approach used by every
    -- "universal sit anywhere" script -- there is no per-model calibration
    -- data available without visually testing each prop in-game).
    heightOffset = 0.02,
}
