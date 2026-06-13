-- ============================================================
--  NX-Core — Shared Items
--  Lista de items para validacao server-side e acesso rapido.
--  NAO substitui o ox_inventory — e uma cache de referencia.
-- ============================================================

NXCore.Shared = NXCore.Shared or {}

NXCore.Shared.Items = {
    -- -----------------------------------------------
    --  Dinheiro / Contas
    -- -----------------------------------------------
    ['black_money'] = {
        label       = 'Dinheiro Sujo',
        weight      = 1,
        stack       = false,
        usable      = false,
        description = 'Dinheiro de origem ilicita.',
    },

    -- -----------------------------------------------
    --  Consumiveis
    -- -----------------------------------------------
    ['water'] = {
        label       = 'Agua',
        weight      = 500,
        stack       = true,
        usable      = true,
        description = 'Hidrata o jogador.',
    },
    ['cola'] = {
        label       = 'Cola',
        weight      = 400,
        stack       = true,
        usable      = true,
        description = 'Uma lata de refrigerante.',
    },
    ['burger'] = {
        label       = 'Hamburguer',
        weight      = 300,
        stack       = true,
        usable      = true,
        description = 'Um hamburguer delicioso.',
    },
    ['sandwich'] = {
        label       = 'Sanduiche',
        weight      = 200,
        stack       = true,
        usable      = true,
        description = 'Uma sanduiche simples.',
    },

    -- -----------------------------------------------
    --  Medicos / Primeiros Socorros
    -- -----------------------------------------------
    ['bandage'] = {
        label       = 'Ligadura',
        weight      = 100,
        stack       = true,
        usable      = true,
        description = 'Recupera um pouco de vida.',
    },
    ['firstaid'] = {
        label       = 'Kit de Primeiros Socorros',
        weight      = 500,
        stack       = true,
        usable      = true,
        description = 'Recupera bastante vida.',
    },
    ['morphine'] = {
        label       = 'Morfina',
        weight      = 100,
        stack       = true,
        usable      = true,
        description = 'Analgésico medico.',
    },

    -- -----------------------------------------------
    --  Ferramentas
    -- -----------------------------------------------
    ['lockpick'] = {
        label       = 'Ganzua',
        weight      = 200,
        stack       = true,
        usable      = true,
        description = 'Permite abrir fechaduras.',
    },
    ['advancedlockpick'] = {
        label       = 'Ganzua Avancada',
        weight      = 300,
        stack       = true,
        usable      = true,
        description = 'Permite abrir fechaduras de alta seguranca.',
    },
    ['repairkit'] = {
        label       = 'Kit de Reparacao',
        weight      = 1000,
        stack       = true,
        usable      = true,
        description = 'Repara parcialmente um veiculo.',
    },
    ['advancedrepairkit'] = {
        label       = 'Kit de Reparacao Avancado',
        weight      = 2000,
        stack       = true,
        usable      = true,
        description = 'Repara totalmente um veiculo.',
    },
    ['phone'] = {
        label       = 'Telemovel',
        weight      = 200,
        stack       = false,
        usable      = true,
        description = 'Um telemovel.',
    },

    -- -----------------------------------------------
    --  Documentos / Identificacao
    -- -----------------------------------------------
    ['id_card'] = {
        label       = 'Cartao de Cidadao',
        weight      = 0,
        stack       = false,
        usable      = false,
        description = 'Documento de identificacao oficial.',
    },
    ['driver_license'] = {
        label       = 'Carta de Conducao',
        weight      = 0,
        stack       = false,
        usable      = false,
        description = 'Carta de conducao valida.',
    },
    ['weapon_license'] = {
        label       = 'Licenca de Armas',
        weight      = 0,
        stack       = false,
        usable      = false,
        description = 'Licenca para porte de arma.',
    },

    -- -----------------------------------------------
    --  Materias Primas / Crafting
    -- -----------------------------------------------
    ['steel'] = {
        label       = 'Aco',
        weight      = 2000,
        stack       = true,
        usable      = false,
        description = 'Materia-prima metalica.',
    },
    ['plastic'] = {
        label       = 'Plastico',
        weight      = 500,
        stack       = true,
        usable      = false,
        description = 'Materia-prima plastica.',
    },
    ['rubber'] = {
        label       = 'Borracha',
        weight      = 800,
        stack       = true,
        usable      = false,
        description = 'Materia-prima elastica.',
    },
    ['glass'] = {
        label       = 'Vidro',
        weight      = 1500,
        stack       = true,
        usable      = false,
        description = 'Materia-prima fragil.',
    },
    ['copper'] = {
        label       = 'Cobre',
        weight      = 1800,
        stack       = true,
        usable      = false,
        description = 'Metal condutor.',
    },
    ['gold'] = {
        label       = 'Ouro',
        weight      = 3000,
        stack       = true,
        usable      = false,
        description = 'Metal precioso.',
    },

    -- -----------------------------------------------
    --  Drogas / Ilicitos
    -- -----------------------------------------------
    ['weed_seed'] = {
        label       = 'Semente de Marijuana',
        weight      = 50,
        stack       = true,
        usable      = false,
        description = 'Semente ilegal.',
    },
    ['weed'] = {
        label       = 'Marijuana',
        weight      = 100,
        stack       = true,
        usable      = true,
        description = 'Substancia ilegal.',
    },
    ['cocaine_brick'] = {
        label       = 'Tijolo de Cocaina',
        weight      = 500,
        stack       = true,
        usable      = false,
        description = 'Substancia ilegal nao processada.',
    },
    ['cocaine'] = {
        label       = 'Cocaina',
        weight      = 100,
        stack       = true,
        usable      = true,
        description = 'Substancia ilegal processada.',
    },
    ['meth'] = {
        label       = 'Metanfetamina',
        weight      = 100,
        stack       = true,
        usable      = true,
        description = 'Substancia ilegal sintetica.',
    },

    -- -----------------------------------------------
    --  Outros
    -- -----------------------------------------------
    ['garbage'] = {
        label       = 'Lixo',
        weight      = 100,
        stack       = true,
        usable      = false,
        description = 'Lixo recolhido.',
    },
    ['radio'] = {
        label       = 'Radio',
        weight      = 500,
        stack       = false,
        usable      = true,
        description = 'Radio de comunicacao.',
    },
    ['handcuffs'] = {
        label       = 'Algemas',
        weight      = 500,
        stack       = true,
        usable      = true,
        description = 'Para deter suspeitos.',
    },
    ['evidence_bag'] = {
        label       = 'Saco de Evidencias',
        weight      = 200,
        stack       = true,
        usable      = false,
        description = 'Para recolher evidencias.',
    },
}

-- -----------------------------------------------
--  Funcao auxiliar: verifica se item existe
-- -----------------------------------------------
function NXCore.ItemExists(itemName)
    return NXCore.Shared.Items[itemName] ~= nil
end

-- -----------------------------------------------
--  Funcao auxiliar: obtem dados de um item
-- -----------------------------------------------
function NXCore.GetItem(itemName)
    return NXCore.Shared.Items[itemName]
end

NXCore.Debug('info', 'Shared Items carregados — %d items.', (function()
    local c = 0; for _ in pairs(NXCore.Shared.Items) do c = c + 1 end; return c
end)())