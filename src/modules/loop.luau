type Array<T> = { T }

export type System = (number) -> ...(number) -> ()

type GroupInfo = { i: number?, o: number? }

type SystemGroup = {
    interval: number,
    offset: number,
    dt: number,
    [number]: {
        name: string,
        type: number,
        fn: (...any) -> ...any
    }
}

local function run_sys(name: string, fn: (...unknown) -> (), ...: unknown)
    local thread = coroutine.create(function(...)
        local ok, err: string? = xpcall(fn, function(err: string)
            local trace = debug.traceback(nil, 2)
            return `ERROR:\n{err}\n\nTRACE:\n{trace}`
        end, ...)

        return ok, err
    end)

    local _, ok, result = coroutine.resume(thread, ...)

    if not ok then
        warn(`system "{name}" errored\n\n{result}`)
    end

    if coroutine.status(thread) == "suspended" then
        warn(`system "{name}" yielded`)
    end
end

local function loop_create(...: ModuleScript | () -> () | GroupInfo): (number) -> ()
    local groups = {} :: Array<SystemGroup>

    local current_group: SystemGroup?

    local function process_systems(array: Array<any>)
        for i, v in array do
            if type(v) == "table" then
                if v.i then
                    if current_group then
                        table.insert(groups, current_group)
                    end

                    current_group = {
                        interval = v.i or 1,
                        offset = v.o or 0,
                        dt = 0
                    }
                else
                    process_systems(v)
                end
            elseif type(v) == "function" then 
                assert(current_group)

                table.insert(current_group, {
                    name = "UNNAMED",
                    type = 0,
                    fn = v
                })
            else
                assert(current_group)

                local fn = (require :: any)(v) :: System
                local fn2 = fn(0)

                table.insert(current_group, {
                    name = v.Name,
                    type = fn2 and 1 or 0,
                    fn = fn2 or fn
                })
            end
        end
    end

    process_systems { ... }

    assert(current_group)
    table.insert(groups, current_group)
    current_group = nil

    local frame_count = 0

    return function(dt)
        frame_count += 1

        debug.profilebegin("ECS LOOP")

        for _, group in groups do
            group.dt += dt

            if frame_count % group.interval == group.offset then
                for _, system in ipairs(group) do
                    debug.setmemorycategory(system.name)
                    debug.profilebegin(system.name)

                    if system.type == 0 then
                        run_sys(system.name, system.fn, group.dt)
                    else
                        run_sys(system.name, system.fn, group.dt)
                    end

                    debug.profileend()
                end

                group.dt = 0
            end
        end

        debug.resetmemorycategory()
        debug.profileend()
    end
end

return loop_create