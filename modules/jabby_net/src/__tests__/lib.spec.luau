--!nonstrict

local gt = require(script.Parent.Parent.Parent.roblox_packages.gt)
local jabby_util = require(script.Parent.Parent.Parent.roblox_packages.jabby_util)
local jest_globals = require(script.Parent.Parent.Parent.roblox_packages.jest_globals)
local lib = require(script.Parent.Parent.lib)

local beforeEach = jest_globals.beforeEach
local describe = jest_globals.describe
local it = jest_globals.it
local expect = jest_globals.expect

local ANY = gt.any({allowNil = true})

beforeEach(function()
	lib.set_auth_callback(function()
		return true
	end)
end)

describe("event", function()
	it("should create event channel", function()
		local event_channel = lib.event_create("testing", "event_1", ANY)
		expect(event_channel).toBeDefined(nil)
	end)

	it("should fire and receive", function(_, done)
		local event_channel = lib.event_create("testing", "event_2", ANY)
		local n = math.random()

		event_channel:connect(1):on_event(function(sender, value)
			expect(value).toBe(n)
			done()
		end)

		event_channel:fire({ to = "server", id = 1 }, n)
	end)

	it("should iterate", function()
		local event_channel = lib.event_create("testing", "event_3", ANY)
		local connected = event_channel:connect(1)

		for i = 1, 10 do
			event_channel:fire({ to = "server", id = 1 }, i)
		end

		local idx = 1
		for sender, value in connected:iter() do
			expect(value).toBe(idx)
			idx += 1
		end
	end)

	it.failing("should fail with incorrect types", function()
		local event_channel = lib.event_create("testing", "event_3.5", gt.number())
		local connected = event_channel:connect(1)

		event_channel:fire({ to = "server", id = 1 }, false)

		for sender, value in connected:iter() do
		end
	end)

	it("should block requests", function()
		local event_channel = lib.event_create("testing", "event_4", ANY)
		local connection = event_channel:connect(1)
		local allow = false

		type TestAction = {
			allow: boolean
		}

		connection:set_permission_data(function(sender, data)
			return {
				user = sender.to,
				action = "meow",
				allow = allow
			}
		end)

		lib.set_auth_callback(function(data: TestAction)
			return data.allow
		end)

		allow = false
		event_channel:fire({ to = "server", id = 1 }, 1)
		event_channel:fire({ to = "server", id = 1 }, 2)
		event_channel:fire({ to = "server", id = 1 }, 3)
		event_channel:fire({ to = "server", id = 1 }, 4)
		event_channel:fire({ to = "server", id = 1 }, 5)
		allow = true
		event_channel:fire({ to = "server", id = 1 }, 6)
		event_channel:fire({ to = "server", id = 1 }, 7)
		event_channel:fire({ to = "server", id = 1 }, 8)
		event_channel:fire({ to = "server", id = 1 }, 9)
		event_channel:fire({ to = "server", id = 1 }, 10)

		local idx = 6
		for sender, value in connection:iter() do
			expect(value).toBe(idx)
			idx += 1
		end

	end)

	it("should not fire for different ids", function()
		local event_channel = lib.event_create("testing", "event_4", ANY)
		local connection = event_channel:connect(1)

		event_channel:fire({ to = "server", id = 2 }, 1)
		event_channel:fire({ to = "server", id = 2 }, 2)
		event_channel:fire({ to = "server", id = 2 }, 3)
		event_channel:fire({ to = "server", id = 2 }, 4)
		event_channel:fire({ to = "server", id = 2 }, 5)

		event_channel:fire({ to = "server", id = 1 }, 6)
		event_channel:fire({ to = "server", id = 1 }, 7)
		event_channel:fire({ to = "server", id = 1 }, 8)
		event_channel:fire({ to = "server", id = 1 }, 9)
		event_channel:fire({ to = "server", id = 1 }, 10)

		local idx = 6
		for sender, value in connection:iter() do
			expect(value).toBe(idx)
			idx += 1
		end
	end)
end)

describe("function", function()

	it("should create function channel", function()
		local function_channel = lib.function_create("function", "func", gt.number(), gt.number())
		
		expect(function_channel).toBeDefined(nil)
	end)

	it("should invoke and receive", function()
		local channel = lib.function_create("function", "event_2", gt.number(), gt.number())
		local connection = channel:connect(1)
		local n = math.random()

		connection:on_invoke(function(sender, data)
			expect(data).toBe(n)
			return data + 1
		end)

		local result = channel:invoke({ to = "server", id = 1 }, n)
		local value = result:await()

		expect(value.why).toBe(nil)
		assert(value.ok)
		expect(value.value).toBe(n + 1)
	end, 100)

	it("should iterate", function(_, done)
		local channel = lib.function_create("function", "event_3", gt.number(), gt.number())
		local connection = channel:connect(1)

		channel:invoke({ to = "server", id = 1 }, 1):after(function(result)
			expect(result.value).toBe(2)
			done()
		end)

		task.wait()

		for sender, resolve, value in connection:iter() do
			resolve(value + 1)
		end

		task.wait()
	end, 500)

	it("should block requests", function()
		local channel = lib.function_create("function", "event_4", gt.number(), gt.number())
		local connection = channel:connect(1)
		local allow = false

		type TestAction = {
			allow: boolean
		}

		connection:set_permission_data(function(sender, data)
			return {
				user = sender.to,
				action = "meow",
				allow = allow
			}
		end)

		lib.set_auth_callback(function(data: TestAction)
			return data.allow
		end)

		local n = 0
		local function expect_false(value: jabby_util.Result)
			n += 1
			expect(value.ok).toBe(false)
		end
		
		local function expect_true(idx: number)
			return function(value: jabby_util.Result)
				n += 1
				expect(value.ok).toBe(true)
				expect(value.value).toBe(idx)
			end
		end

		allow = false
		channel:invoke({ to = "server", id = 1 }, 1):after(expect_false)
		channel:invoke({ to = "server", id = 1 }, 2):after(expect_false)
		channel:invoke({ to = "server", id = 1 }, 3):after(expect_false)
		channel:invoke({ to = "server", id = 1 }, 4):after(expect_false)
		channel:invoke({ to = "server", id = 1 }, 5):after(expect_false)
		task.wait()

		allow = true
		channel:invoke({ to = "server", id = 1 }, 6):after(expect_true(6))
		channel:invoke({ to = "server", id = 1 }, 7):after(expect_true(7))
		channel:invoke({ to = "server", id = 1 }, 8):after(expect_true(8))
		channel:invoke({ to = "server", id = 1 }, 9):after(expect_true(9))
		channel:invoke({ to = "server", id = 1 }, 10):after(expect_true(10))

		task.wait()

		local idx = 6
		for sender, resolve, value in connection:iter() do
			expect(value).toBe(idx)
			resolve(value)
			idx += 1
		end

		task.wait()

		expect(n).toBe(10)
	end, 500)

	it("should not invoke for different ids", function()
		local channel = lib.function_create("function", "event_5", gt.number(), gt.number())
		local connection = channel:connect(1)

		channel:invoke({ to = "server", id = 2 }, 1)

		task.wait()

		for sender, resolve, value in connection:iter() do
			error("false")
		end

		local r = channel:invoke({ to = "server", id = 1 }, 2)
		task.wait()
		for sender, resolve, value in connection:iter() do
			expect(value).toBe(2)
			resolve(3)
		end

		expect(r:await().ok).toBe(true)
		expect(r:await().value).toBe(3)
	end, 100)
end)

-- describe("socket", function()
-- 	local layer = lib.create_network_layer("should_create_socket", 1)

-- 	it("should create socket channel", function()
-- 		local function_channel = layer:create_socket_channel("func", ANY)
		
-- 		expect(function_channel).toBeDefined(nil)
-- 	end)

-- 	it("should request and receive", function(_, done)
-- 		local channel = lib.function_create("function", "event_2", ANY)
-- 		local n = math.random()

-- 		channel:set_on_invoke(function(sender, data)
-- 			expect(data).toBe(n)
-- 			return data + 1
-- 		end)

-- 		local result = channel:invoke({ to = "server", id = 1 })
-- 		local value = result:await()

-- 		expect(value.ok).toBe(true)
-- 		assert(value.ok)
-- 		expect(value.value).toBe(n + 1)
-- 	end, 1)

-- 	it("should iterate", function(_, done)
-- 		local channel = lib.function_create("function", "event_3", ANY)
-- 		local yield = channel:invoke({ to = "server", id = 1 }, 1)

-- 		for sender, resolve, value in channel:iter() do
-- 			resolve(value + 1)
-- 		end

-- 		local result = yield:await()
-- 		expect(result.ok).toBe(true)
-- 		assert(result.ok)
-- 		expect(result.value).toBe(2)
-- 	end, 1)

-- 	it("should block requests", function()
-- 		local channel = lib.function_create("function", "event_4", ANY)
-- 		local allow = false

-- 		type TestAction = {
-- 			allow: boolean
-- 		}

-- 		channel:set_permission_callback(function(sender, data)
-- 			return {
-- 				user = sender.to,
-- 				action = "meow",
-- 				allow = allow
-- 			}
-- 		end)

-- 		lib.set_user_defined_permission(function(data: TestAction)
-- 			return data.allow
-- 		end)

-- 		local n = 0
-- 		local function expect_false(value: jabby_util.Result)
-- 			n += 1
-- 			expect(value.ok).toBe(false)
-- 		end
		
-- 		local function expect_true(idx: number)
-- 			return function(value: jabby_util.Result)
-- 				n += 1
-- 				expect(value.ok).toBe(true)
-- 				expect(value.value).toBe(idx)
-- 			end
-- 		end

-- 		allow = false
-- 		channel:invoke({ to = "server", id = 1 }, 1):after(expect_false)
-- 		channel:invoke({ to = "server", id = 1 }, 2):after(expect_false)
-- 		channel:invoke({ to = "server", id = 1 }, 3):after(expect_false)
-- 		channel:invoke({ to = "server", id = 1 }, 4):after(expect_false)
-- 		channel:invoke({ to = "server", id = 1 }, 5):after(expect_false)
-- 		allow = true
-- 		channel:invoke({ to = "server", id = 1 }, 6):after(expect_true(6))
-- 		channel:invoke({ to = "server", id = 1 }, 7):after(expect_true(7))
-- 		channel:invoke({ to = "server", id = 1 }, 8):after(expect_true(8))
-- 		channel:invoke({ to = "server", id = 1 }, 9):after(expect_true(9))
-- 		channel:invoke({ to = "server", id = 1 }, 10):after(expect_true(10))

-- 		local idx = 6
-- 		for sender, resolve, value in channel:iter() do
-- 			expect(value).toBe(idx)
-- 			resolve(value)
-- 			idx += 1
-- 		end

-- 		while n ~= 10 do task.wait() end
-- 	end, 1)

-- 	it("should not invoke for different ids", function()
-- 		local channel = lib.function_create("function", "event_4", ANY)
-- 		channel:invoke({ to = "server", id = 2 }, 1)

-- 		for sender, resolve, value in channel:iter() do
-- 			error("false")
-- 		end

-- 		local r = channel:invoke({ to = "server", id = 1 }, 2)
-- 		for sender, resolve, value in channel:iter() do
-- 			expect(value).toBe(2)
-- 			resolve(3)
-- 		end

-- 		expect(r:await().ok).toBe(true)
-- 		expect(r:await().value).toBe(3)
-- 	end, 1)
-- end)