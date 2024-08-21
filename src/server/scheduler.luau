local types = require(script.Parent.Parent.modules.types)

type SystemId = types.SystemId
type SystemSettingData = types.SystemSettingData
type SystemTag = types.SystemTag

type SystemData = {}
type ProcessingFrame = {
	started_at: number
}
type SystemFrame = {
	s: number
}

local MAX_BUFFER_SIZE = 50

local function create_scheduler(name: string)

	local count = 1

	local scheduler = {
		scheduler_name = name,

		--- contains a map of valid system ids
		valid_system_ids = {} :: {[SystemId]: true},
		--- contains a list of static system data that is updated infrequently
		system_data = {} :: {[SystemId]: SystemData},
		--- contains a buffer of the last couple frames of system data that is
		--- refreshed constantly
		system_frames = {} :: {[SystemId]: {SystemFrame}},
		--- contains the current frame that a system is processing
		processing_frame = {} :: {[SystemId]: ProcessingFrame}

	}

	local function ASSERT_SYSTEM_VALID(id: SystemId)
		assert(scheduler.valid_system_ids[id], `attempt to use unknown system with id #{id}`)
	end

	function scheduler:register_system()
		local id = count; count += 1
		scheduler.valid_system_ids[id] = true
		scheduler.system_data[id] = {}
		scheduler.system_frames[id] = {}
		return id
	end

	function scheduler:set_system_data(id: SystemId, settings: types.SystemSettingData)
		ASSERT_SYSTEM_VALID(id)

		for key, value in settings do
			scheduler.system_data[id][key] = value
		end
	end

	function scheduler:remove_system(id: SystemId)
		scheduler.valid_system_ids[id] = nil
		scheduler.system_data[id] = nil
		scheduler.system_frames[id] = nil
	end

	function scheduler:mark_system_frame_start(id: SystemId)
		ASSERT_SYSTEM_VALID(id)

		scheduler.processing_frame[id] = {
			started_at = os.clock()
		}
	end

	function scheduler:mark_system_frame_end(id: SystemId, s: number?)
		ASSERT_SYSTEM_VALID(id)
		local now = os.clock()
		local frame = scheduler.processing_frame[id]
		assert(frame ~= nil, "no processing frame")

		scheduler.processing_frame[id] = nil
		table.insert(scheduler.system_frames[id], 1, {s = now - frame.started_at})
		table.remove(scheduler.system_frames[id], MAX_BUFFER_SIZE)
	end

	function scheduler:append_extra_frame_data(id: SystemId, label: {})
		--todo
		assert("todo")
	end

	function scheduler:run_system<T...>(id: SystemId, system: (T...) -> (), ...: T...)
		ASSERT_SYSTEM_VALID(id)
		scheduler:mark_system_frame_start(id)
		system(...)
		scheduler:mark_system_frame_end(id)
	end

	return scheduler

end

return {

	create = create_scheduler

}