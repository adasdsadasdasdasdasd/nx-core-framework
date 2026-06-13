-- ============================================================
--  NX-Core — Shared Gangs
--  REGRA: Ao entrar numa gang, o job passa para 'unemployed'.
--  Ao definir um job, a gang passa para 'none'.
-- ============================================================

NXCore.Shared = NXCore.Shared or {}

NXCore.Shared.Gangs = {
    ['none'] = {
        label  = 'Sem Gangue',
        grades = {
            [0] = { label = 'Sem Gangue', salary = 0, isBoss = false },
        },
    },
    ['crimorg'] = {
        label  = 'Organizacao Criminosa',
        grades = {
            [0] = { label = 'Prospeto', salary = 200,  isBoss = false },
            [1] = { label = 'Soldado',  salary = 500,  isBoss = false },
            [2] = { label = 'Capitao',  salary = 900,  isBoss = false },
            [3] = { label = 'Boss',     salary = 1500, isBoss = true  },
        },
    },
    ['vagos'] = {
        label  = 'Los Vagos',
        grades = {
            [0] = { label = 'Prospeto', salary = 150,  isBoss = false },
            [1] = { label = 'Membro',   salary = 400,  isBoss = false },
            [2] = { label = 'Veterano', salary = 700,  isBoss = false },
            [3] = { label = 'Lider',    salary = 1200, isBoss = true  },
        },
    },
    ['ballas'] = {
        label  = 'Ballas',
        grades = {
            [0] = { label = 'Prospeto', salary = 150,  isBoss = false },
            [1] = { label = 'Membro',   salary = 400,  isBoss = false },
            [2] = { label = 'Veterano', salary = 700,  isBoss = false },
            [3] = { label = 'Lider',    salary = 1200, isBoss = true  },
        },
    },
    ['marabunta'] = {
        label  = 'Marabunta Grande',
        grades = {
            [0] = { label = 'Recruta',  salary = 200,  isBoss = false },
            [1] = { label = 'Soldado',  salary = 500,  isBoss = false },
            [2] = { label = 'Capitao',  salary = 900,  isBoss = false },
            [3] = { label = 'Padrinho', salary = 1500, isBoss = true  },
        },
    },
    ['lost'] = {
        label  = 'The Lost MC',
        grades = {
            [0] = { label = 'Hang-Around',     salary = 200,  isBoss = false },
            [1] = { label = 'Prospect',        salary = 450,  isBoss = false },
            [2] = { label = 'Member',          salary = 700,  isBoss = false },
            [3] = { label = 'Vice President',  salary = 1000, isBoss = false },
            [4] = { label = 'President',       salary = 1600, isBoss = true  },
        },
    },
}

function NXCore.GetGangGradeLabel(gangName, grade)
    local gang = NXCore.Shared.Gangs[gangName]
    if not gang then return tostring(grade) end
    local gradeData = gang.grades[tonumber(grade)]
    return gradeData and gradeData.label or tostring(grade)
end

function NXCore.GetGangSalary(gangName, grade)
    local gang = NXCore.Shared.Gangs[gangName]
    if not gang then return 0 end
    local gradeData = gang.grades[tonumber(grade)]
    return gradeData and gradeData.salary or 0
end

function NXCore.IsGangBoss(gangName, grade)
    local gang = NXCore.Shared.Gangs[gangName]
    if not gang then return false end
    local gradeData = gang.grades[tonumber(grade)]
    return gradeData and gradeData.isBoss == true or false
end

function NXCore.GangExists(gangName)
    return NXCore.Shared.Gangs[gangName] ~= nil
end

NXCore.Debug('info', 'Shared Gangs carregadas — %d gangues.', (function()
    local c = 0; for _ in pairs(NXCore.Shared.Gangs) do c = c + 1 end; return c
end)())