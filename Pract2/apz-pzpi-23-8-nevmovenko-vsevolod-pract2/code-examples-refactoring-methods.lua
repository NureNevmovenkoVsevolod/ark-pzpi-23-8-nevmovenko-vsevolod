-- ---------- 3.1 Replace Magic Number with Symbolic Constant ----------
--[[ ПОГАНО: Числа 200 та 3600 не мають семантичного значення ]]
local function set_cache()
    if get_status() == 200 then
        ngx.header["TTL"] = 3600
        return ngx.exit(200)
    end
end

--[[ ДОБРЕ: Використання констант робить код зрозумілим та легким для зміни ]]
local HTTP_OK = ngx.HTTP_OK
local CACHE_TTL = 3600 -- 1 година в секундах

local function set_cache()
    if get_status() == HTTP_OK then
        ngx.header["TTL"] = CACHE_TTL
        return ngx.exit(HTTP_OK)
    end
end


-- ---------- 3.2 Replace Nested Conditional with Guard Clauses ----------
--[[ ПОГАНО: "Ефект піраміди" через вкладені умови ]]
local function process_data(data)
    if data then
        if data.id then
            if data.active then
                return save(data)
            end
        end
    end
end

--[[ ДОБРЕ: Лінійна структура, перевірки помилок на самому початку ]]
local function process_data(data)
    if not data then return nil end
    if not data.id then return nil end
    if not data.active then 
        return nil, "inactive" 
    end

    return save(data) -- Основна логіка на верхньому рівні
end


-- ---------- 3.3 Replace Temp with Query ----------
--[[ ПОГАНО: Тимчасова змінна 'sig' забруднює область видимості ]]
local function send_response(data)
    local sig = ngx.md5(data .. salt)
    ngx.header["X-Auth-Sig"] = sig
    ngx.say(data)
end

--[[ ДОБРЕ: Логіка обчислення винесена в окрему функцію-запит ]]
local function get_auth_sig(d)
    return ngx.md5(d .. salt)
end

local function send_response(data)
    ngx.header["X-Auth-Sig"] = get_auth_sig(data)
    ngx.say(data)
end


-- ---------- 3.4 Комплексний рефакторинг (handle_api_request) ----------
--[[ ПІСЛЯ РЕФАКТОРИНГУ: поєднання всіх методів ]]
local HTTP_OK = ngx.HTTP_OK
local HTTP_FORBIDDEN = ngx.HTTP_FORBIDDEN
local RATE_LIMIT = 1000

local function get_sig(key)
    return ngx.md5(key .. secret_salt)
end

local function handle_api_request(req)
    -- 1. Inline: прямий доступ до поля
    local key = req.api_key

    -- 2. Guard Clauses: швидкий вихід при помилках
    if not key or #key ~= 32 then
        return ngx.exit(HTTP_FORBIDDEN)
    end

    if ngx.shared.limit_store:get(key) >= RATE_LIMIT then
        return ngx.exit(429)
    end

    -- 3. Чистий успішний сценарій
    ngx.header["X-Auth-Sig"] = get_sig(key)
    return ngx.exit(HTTP_OK)
end