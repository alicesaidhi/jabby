local types = require(script.Parent.Parent.modules.types)

type SystemId = types.SystemId
type SystemSettingData = types.SystemSettingData
type SystemTag = types.SystemTag

type SystemData = types.SystemData
type ProcessingFrame = {
	started_at: number
}
type SystemFrame = types.SystemFrame

local MAX_BUFFER_SIZE = 50

local n = 0
local schedulers = {}

local function create_scheduler(name: string)

	local count = 1
	local frames = 0

	local scheduler = {
		class_name = "Scheduler",
		name = name,

		--- contains a map of valid system ids
		valid_system_ids = {} :: {[SystemId]: true},
		--- contains a list of static system data that is updated infrequently
		system_data = {} :: {[SystemId]: SystemData},
		--- list of system data that has updated
		system_data_updated = {} :: {[SystemId]: true},
		--- contains a buffer of the last couple frames of system data that is
		--- refreshed constantly
		system_frames = {} :: {[SystemId]: {SystemFrame}},
		--- stores the frames that have been updated
		system_frames_updated = {} :: {[SystemId]: {[SystemFrame]: true}},
		--- contains the current frame that a system is processing
		processing_frame = {} :: {[SystemId]: ProcessingFrame}

	}

	local function ASSERT_SYSTEM_VALID(id: SystemId)
		assert(scheduler.valid_system_ids[id], `attempt to use unknown system with id #{id}`)
	end

	function scheduler:register_system(settings: types.SystemSettingData?)
		local id = count; count += 1
		scheduler.valid_system_ids[id] = true
		scheduler.system_data[id] = {
			name = "UNNAMED",
			phase = nil,
			layout_order = 0,
			paused = false
		}
		scheduler.system_frames[id] = {}
		scheduler.system_frames_updated[id] = {}
		
		if settings then
			scheduler:set_system_data(id, settings)
		end

		return id
	end

	function scheduler:set_system_data(id: SystemId, settings: types.SystemSettingData)
		ASSERT_SYSTEM_VALID(id)

		for key, value in settings do
			scheduler.system_data[id][key] = value
		end
		scheduler.system_data_updated[id] = true
	end

	function scheduler:remove_system(id: SystemId)
		scheduler.valid_system_ids[id] = nil
		scheduler.system_data[id] = nil
		scheduler.system_frames[id] = nil
		scheduler.system_frames_updated[id] = nil
		scheduler.system_data_updated[id] = true
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
		local pending_frame_data = scheduler.processing_frame[id]
		assert(pending_frame_data ~= nil, "no processing frame")
		local frame = {
			i = frames,
			s = now - pending_frame_data.started_at
		}

		frames += 1

		scheduler.processing_frame[id] = nil
		scheduler.system_frames_updated[id][frame] = true
		local last_frame = scheduler.system_frames[id][MAX_BUFFER_SIZE]
		if last_frame then
			scheduler.system_frames_updated[id][last_frame] = nil
		end

		table.insert(scheduler.system_frames[id], 1, frame)
		table.remove(scheduler.system_frames[id], MAX_BUFFER_SIZE + 1)
	end

	function scheduler:append_extra_frame_data(id: SystemId, label: {})
		--todo
		assert("todo")
	end

	function scheduler:run<T...>(id: SystemId, system: (T...) -> (), ...: T...)
		ASSERT_SYSTEM_VALID(id)
		local system_data = scheduler.system_data[id]

		if system_data.paused then return end

		scheduler:mark_system_frame_start(id)
		system(...)
		scheduler:mark_system_frame_end(id)
	end

	schedulers[n + 1] = scheduler
	n = n + 1

	return scheduler

end

return {

	create = create_scheduler,
	schedulers = schedulers

}