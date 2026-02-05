-- ---------- 3.1 Відступи та форматування блоків ----------
--[[ Хороший код (4 пробіли, стандарт OpenResty) ]]
local function process_data(data)
    if not data then
        return nil, "no data provided"
    end

    for i, item in ipairs(data) do
        print("Processing item: ", item)
    end

    return true
end

--[[ Поганий код (2 пробіли або табуляція, нечитабельно в Nginx логах) ]]
local function process_data(data)
  if not data then
    return nil, "no data provided"
  end

  for i, item in ipairs(data) do
	  print("Processing item: ", item) -- Змішані таби і пробіли
  end

  return true
end

-- ---------- 3.2 Іменування змінних та функцій ----------
--[[ Хороший код (snake_case, відповідає Nginx API) ]]
local max_connections = 100
local user_id = get_current_user_id()

local function calculate_total_usage(usage_table)
    local total_bytes = 0
    -- логіка
    return total_bytes
end

--[[ Поганий код (CamelCase або PascalCase, чужорідний стиль) ]]
local maxConnections = 100
local UserID = GetCurrentUserID()

local function CalculateTotalUsage(usageTable)
    local TotalBytes = 0
    -- логіка
    return TotalBytes
end

-- ---------- 3.3 Використання локальних змінних (Scope) ----------
--[[ Хороший код (завжди local, безпечно для конкурентних запитів) ]]
local cjson = require "cjson"

local function handler()
    local request_body = ngx.req.get_body_data()
    if not request_body then
        return
    end
    
    local data = cjson.decode(request_body)
end

--[[ Поганий код (глобальні змінні, race conditions між запитами) ]]
-- cjson стає глобальним!
cjson = require "cjson" 

function handler()
    -- request_body потрапляє в _G і може бути перезаписаний іншим запитом
    request_body = ngx.req.get_body_data()
    if not request_body then
        return
    end
    
    data = cjson.decode(request_body)
end

-- ---------- 3.4 Обробка помилок (Error Handling) ----------
--[[ Хороший код (перевірка на nil, повернення помилки другим аргументом) ]]
local res, err = db:query("SELECT * FROM users")

if not res then
    ngx.log(ngx.ERR, "failed to query db: ", err)
    return ngx.exit(500)
end

-- Продовження роботи з res...

--[[ Поганий код (ігнорування можливості помилки, призводить до 500 error) ]]
local res = db:query("SELECT * FROM users")

-- Якщо res == nil, спроба ітерації викличе краш скрипта
for _, row in ipairs(res) do
    -- логіка
end

-- ---------- 3.5 Оптимізація доступу до функцій ----------
--[[ Хороший код (кешування глобальних функцій у локальні змінні) ]]
local table_insert = table.insert
local string_len = string.len

local function process_list(items)
    local result = {}
    for _, item in ipairs(items) do
        if string_len(item) > 5 then
            table_insert(result, item)
        end
    end
    return result
end

--[[ Поганий код (постійний пошук у глобальній таблиці _G) ]]
local function process_list(items)
    local result = {}
    for _, item in ipairs(items) do
        -- Lua змушена шукати 'string' та 'len' на кожній ітерації
        if string.len(item) > 5 then
            table.insert(result, item)
        end
    end
    return result
end

-- ---------- 3.6 Ефективна конкатенація рядків ----------
--[[ Хороший код (використання таблиці як буфера) ]]
local table_concat = table.concat

local function build_response(chunks)
    local buffer = {}
    
    for i, chunk in ipairs(chunks) do
        buffer[i] = chunk
    end
    
    -- Створення рядка за один прохід
    return table_concat(buffer)
end

--[[ Поганий код (використання оператора .., навантаження на GC) ]]
local function build_response(chunks)
    local result = ""
    
    for _, chunk in ipairs(chunks) do
        -- Створює новий об'єкт рядка на кожній ітерації (квадратична складність)
        result = result .. chunk
    end
    
    return result
end