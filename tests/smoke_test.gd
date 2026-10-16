extends SceneTree

func _init() -> void:
	var failures: Array[String] = []
	var packed := load("res://scenes/kitchen/kitchen.tscn") as PackedScene
	if packed == null:
		failures.append("Scene dapur gagal dimuat")
	else:
		var kitchen := packed.instantiate()
		root.add_child(kitchen)
		await process_frame
		if not kitchen.has_method("_check"):
			failures.append("Controller aktivitas tidak aktif")
		if kitchen.objects.size() < 3:
			failures.append("Jumlah benda interaktif kurang")
		if kitchen.TARGETS.size() != 3:
			failures.append("Target meja tidak lengkap")
		kitchen.cabinet_open = true
		kitchen.objects["plate"].visible = true
		kitchen.objects["cup"].visible = true
		kitchen._pointer(kitchen.objects["plate"].pos, true)
		if kitchen.active != "plate":
			failures.append("Benda di dalam lemari tidak bisa diambil")
		kitchen._pointer(kitchen.objects["plate"].pos, false)
		kitchen.wash = 1.0
		kitchen.faucet_on = false
		for id in kitchen.TARGETS:
			kitchen.objects[id].pos = kitchen.TARGETS[id]
		kitchen._check()
		if not kitchen.completed:
			failures.append("Kondisi selesai tidak tercapai")
		kitchen.queue_free()
	if failures.is_empty():
		print("SMOKE TEST PASSED: scene, interaksi, dan kondisi selesai valid")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

