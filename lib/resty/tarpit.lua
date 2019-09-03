local _M = {}

local cjson = require "cjson"

_M.version = "0.1"

local function _do_tarpit(t)
	ngx.sleep(t)
	ngx.exit(429) -- Too Many Requests
end

local function _step_down(premature, key, reset)
	local tarpit = ngx.shared.tarpit
	local res = tarpit:get(key)
	local t = cjson.decode(res)

	ngx.update_time()

	-- reduce the state if the key hasnt been touched in 'delay' seconds
	if ((ngx.now() - t.mostrecent) > reset) then
		if (t.state > 0) then t.state = t.state - 1 end
		t.statestart = ngx.now()
		t.staterequests = 0
		tarpit:set(key, cjson.encode(t))
	end

	-- keep looping this until we've decremented our state to 0
	if (t.state > 0) then ngx.timer.at(reset, _step_down, key, reset) end
end

-- request_limit: how many requests can be sent before the delay is increased
-- reset: how long in seconds until the state is reset
-- delay: initial time to stall the request
function _M.tarpit(request_limit, reset, delay, identifier)
	ngx.update_time()
	local _to_tarpit = false
	local tarpit = ngx.shared.tarpit
	local client = identifier or ngx.var.remote_addr
	local resource = ngx.var.uri
	local key = client .. ":" .. resource

	if not tarpit then
		ngx.exit(ngx.OK) -- silently bail if the user hasn't setup the tarpit shm
	end

	-- TODO: look into lua-resty-lock
	local t = {}
	local res = tarpit:get(key)

	if not res then
		t.staterequests = 0
		t.state = 0
		t.statestart = ngx.now()
		t.mostrecent = ngx.now()
	else
		t = cjson.decode(res)
	end

	-- mark this request
	t.staterequests = t.staterequests + 1
	t.mostrecent = ngx:now()

	-- figure out if we need to tarpit this request
	if (t.staterequests > request_limit or t.state > 0) then
		_to_tarpit = true
	end

	-- do we need to bump states?
	if (t.staterequests > request_limit) then
		t.state = t.state + 1
		t.statestart = ngx.now()
		t.staterequests = 0
		-- start the state decrement counter
		-- we only need this to run after the first state bump
		if t.state == 1 then ngx.timer.at(delay, _step_down, key, reset) end
	end

	-- save it up and send em to the grave
	tarpit:set(client .. ":" .. resource, cjson.encode(t))
	if (_to_tarpit) then
		_do_tarpit(delay * t.state)
	end
end

return _M
