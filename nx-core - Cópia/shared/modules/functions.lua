-- ============================================================
--  NX-Core — Funções Utilitárias Partilhadas
-- ============================================================

-- -----------------------------------------------
--  Verifica se uma string não é nil/vazia
-- -----------------------------------------------
function NXCore.IsStringValid(str)
    return type(str) == 'string' and str ~= '' and str ~= 'nil'
end

-- -----------------------------------------------
--  Clamp numérico
-- -----------------------------------------------
function NXCore.Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- -----------------------------------------------
--  Serializa uma tabela em string (debug)
-- -----------------------------------------------
function NXCore.TableToString(tbl, indent)
    indent = indent or 0
    if type(tbl) ~= 'table' then return tostring(tbl) end
    local result = '{\n'
    local spacing = string.rep('  ', indent + 1)
    for k, v in pairs(tbl) do
        local key = type(k) == 'string' and ('"%s"'):format(k) or tostring(k)
        result = result .. spacing .. '[' .. key .. '] = '
        if type(v) == 'table' then
            result = result .. NXCore.TableToString(v, indent + 1)
        else
            result = result .. (type(v) == 'string' and ('"%s"'):format(v) or tostring(v))
        end
        result = result .. ',\n'
    end
    return result .. string.rep('  ', indent) .. '}'
end

-- -----------------------------------------------
--  Divide uma string por separador
-- -----------------------------------------------
function NXCore.SplitString(str, sep)
    local result = {}
    for part in str:gmatch('([^' .. sep .. ']+)') do
        result[#result + 1] = part
    end
    return result
end

-- -----------------------------------------------
--  Capitaliza a primeira letra de cada palavra
-- -----------------------------------------------
function NXCore.Capitalize(str)
    if not NXCore.IsStringValid(str) then return str end
    return str:gsub('(%a)([%w_]*)', function(a, b)
        return a:upper() .. b:lower()
    end)
end

NXCore.Debug('info', 'Shared functions carregadas.')