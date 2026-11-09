extends GutTest


func test_trace_clamps_between_0_and_100() -> void:
	var run := RunState.new(1)
	run.add_trace(-5)
	assert_eq(run.trace, 0)
	run.add_trace(250)
	assert_eq(run.trace, 100)
	assert_true(run.is_traced())


func test_thresholds_fire_once_each_when_crossed() -> void:
	var run := RunState.new(1)
	var fired := []
	run.threshold_crossed.connect(func(t): fired.append(t))
	run.add_trace(30)
	run.add_trace(-10)
	run.add_trace(60)
	assert_eq(fired, [25, 25, 50, 75])
	assert_eq(run.tier(), 3)


func test_moves_cost_trace_at_75() -> void:
	var run := RunState.new(1)
	run.add_trace(75)
	run.begin_move(run.map.start_ids()[0])
	assert_eq(run.trace, 75 + RunState.MOVE_TRACE_AT_75)


func test_outcome_affordability_and_application() -> void:
	var run := RunState.new(1)
	assert_false(run.can_afford_outcome("data:-20;trace:-8"))
	run.data = 20
	run.add_trace(10)
	assert_true(run.can_afford_outcome("data:-20;trace:-8"))
	run.apply_outcome("data:-20;trace:-8;scans:1")
	assert_eq(run.data, 0)
	assert_eq(run.trace, 2)
	assert_eq(run.scans, 3)
