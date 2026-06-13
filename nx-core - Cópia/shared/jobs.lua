-- ============================================================
--  NX-Core — Shared Jobs
--  REGRA: Um jogador NAO pode ter job E gang simultaneamente.
--  Ao definir um job, a gang e automaticamente removida e v.v.
-- ============================================================

NXCore.Shared = NXCore.Shared or {}

NXCore.Shared.Jobs = {
    ['unemployed'] = {
        label  = 'Desempregado',
        isGang = false,
        grades = {
            [0] = { label = 'Desempregado', salary = 0 },
        },
    },
    ['police'] = {
        label  = 'Policia',
        isGang = false,
        grades = {
            [0] = { label = 'Recruta',    salary = 500  },
            [1] = { label = 'Agente',     salary = 800  },
            [2] = { label = 'Sargento',   salary = 1200 },
            [3] = { label = 'Inspetor',   salary = 1800 },
            [4] = { label = 'Comandante', salary = 2500 },
        },
    },
    ['ambulance'] = {
        label  = 'INEM',
        isGang = false,
        grades = {
            [0] = { label = 'Estagiario', salary = 500  },
            [1] = { label = 'Tecnico',    salary = 900  },
            [2] = { label = 'Enfermeiro', salary = 1300 },
            [3] = { label = 'Medico',     salary = 2000 },
            [4] = { label = 'Diretor',    salary = 2800 },
        },
    },
    ['mechanic'] = {
        label  = 'Mecanico',
        isGang = false,
        grades = {
            [0] = { label = 'Aprendiz', salary = 400 },
            [1] = { label = 'Tecnico',  salary = 700 },
            [2] = { label = 'Chefe',    salary = 1100 },
        },
    },
    ['taxi'] = {
        label  = 'Taxista',
        isGang = false,
        grades = {
            [0] = { label = 'Motorista',  salary = 300 },
            [1] = { label = 'Veterano',   salary = 500 },
            [2] = { label = 'Supervisor', salary = 700 },
        },
    },
    ['realestate'] = {
        label  = 'Imobiliaria',
        isGang = false,
        grades = {
            [0] = { label = 'Agente',  salary = 600  },
            [1] = { label = 'Senior',  salary = 1000 },
            [2] = { label = 'Diretor', salary = 1500 },
        },
    },
    ['judge'] = {
        label  = 'Juiz',
        isGang = false,
        grades = {
            [0] = { label = 'Juiz Assistente', salary = 2000 },
            [1] = { label = 'Juiz',            salary = 3500 },
        },
    },
    ['lawyer'] = {
        label  = 'Advogado',
        isGang = false,
        grades = {
            [0] = { label = 'Estagiario', salary = 800  },
            [1] = { label = 'Advogado',   salary = 1500 },
            [2] = { label = 'Socio',      salary = 2500 },
        },
    },
}

function NXCore.GetJobGradeLabel(jobName, grade)
    local job = NXCore.Shared.Jobs[jobName]
    if not job then return tostring(grade) end
    local gradeData = job.grades[tonumber(grade)]
    return gradeData and gradeData.label or tostring(grade)
end

function NXCore.GetJobSalary(jobName, grade)
    local job = NXCore.Shared.Jobs[jobName]
    if not job then return 0 end
    local gradeData = job.grades[tonumber(grade)]
    return gradeData and gradeData.salary or 0
end

function NXCore.JobExists(jobName)
    return NXCore.Shared.Jobs[jobName] ~= nil
end

NXCore.Debug('info', 'Shared Jobs carregados — %d empregos.', (function()
    local c = 0; for _ in pairs(NXCore.Shared.Jobs) do c = c + 1 end; return c
end)())