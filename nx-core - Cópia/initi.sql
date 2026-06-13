-- ============================================================
--  NX-Core — Base de Dados Completa
--  Executa este ficheiro UMA vez no teu servidor MySQL/MariaDB.
--  Cria a DATABASE e todas as tabelas necessarias.
--  Compativel com MySQL 5.7+ e MariaDB 10.3+
-- ============================================================

CREATE DATABASE IF NOT EXISTS `nx_core`
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE `nx_core`;

SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
--  TABLE: nx_players
--  Registo principal de cada jogador.
--  Chave primaria: id (fixo, nunca muda).
--  Chave unica: license (identificador FiveM).
-- ============================================================
CREATE TABLE IF NOT EXISTS `nx_players` (
    `id`            INT(11)       UNSIGNED NOT NULL AUTO_INCREMENT,
    `license`       VARCHAR(64)   NOT NULL,
    `steam`         VARCHAR(64)   DEFAULT NULL,
    `discord`       VARCHAR(64)   DEFAULT NULL,
    `name`          VARCHAR(64)   NOT NULL DEFAULT 'Unknown',
    `firstname`     VARCHAR(64)   NOT NULL DEFAULT 'Desconhecido',
    `lastname`      VARCHAR(64)   NOT NULL DEFAULT 'Desconhecido',
    `dob`           DATE          DEFAULT NULL,
    `sex`           ENUM('m','f') NOT NULL DEFAULT 'm',
    `phone`         VARCHAR(20)   DEFAULT NULL,
    `is_banned`     TINYINT(1)    NOT NULL DEFAULT 0,
    `ban_reason`    VARCHAR(255)  DEFAULT NULL,
    `created_at`    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
                                  ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY  `uq_license`  (`license`),
    INDEX       `idx_steam`   (`steam`),
    INDEX       `idx_discord` (`discord`),
    INDEX       `idx_banned`  (`is_banned`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  TABLE: nx_player_money
--  Saldos do jogador.
--  bank        = dinheiro no banco (limpo).
--  cash_dirty  = dinheiro sujo / ilicito.
-- ============================================================
CREATE TABLE IF NOT EXISTS `nx_player_money` (
    `player_id`     INT(11)    UNSIGNED NOT NULL,
    `bank`          BIGINT(20) UNSIGNED NOT NULL DEFAULT 5000,
    `cash_dirty`    BIGINT(20) UNSIGNED NOT NULL DEFAULT 0,
    `updated_at`    TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP
                               ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`player_id`),
    CONSTRAINT `fk_money_player`
        FOREIGN KEY (`player_id`) REFERENCES `nx_players` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  TABLE: nx_player_jobs
--  Emprego ou gangue atual do jogador.
--  Regra: um jogador so pode ter job OU gang, nunca ambos.
--  is_gang = 0 -> job normal
--  is_gang = 1 -> o campo 'job' contem o nome da gangue
-- ============================================================
CREATE TABLE IF NOT EXISTS `nx_player_jobs` (
    `player_id`     INT(11)     UNSIGNED NOT NULL,
    `job`           VARCHAR(64) NOT NULL DEFAULT 'unemployed',
    `grade`         TINYINT(3)  UNSIGNED NOT NULL DEFAULT 0,
    `is_gang`       TINYINT(1)  NOT NULL DEFAULT 0,
    `updated_at`    TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP
                                ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`player_id`),
    INDEX `idx_pjob_job`     (`job`),
    INDEX `idx_pjob_is_gang` (`is_gang`),
    CONSTRAINT `fk_jobs_player`
        FOREIGN KEY (`player_id`) REFERENCES `nx_players` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  TABLE: nx_player_positions
--  Ultima posicao conhecida do jogador no mundo GTA.
--  Usada para spawn no mesmo local apos reconectar.
-- ============================================================
CREATE TABLE IF NOT EXISTS `nx_player_positions` (
    `player_id`     INT(11)   UNSIGNED NOT NULL,
    `x`             FLOAT     NOT NULL DEFAULT 0.0,
    `y`             FLOAT     NOT NULL DEFAULT 0.0,
    `z`             FLOAT     NOT NULL DEFAULT 0.0,
    `heading`       FLOAT     NOT NULL DEFAULT 0.0,
    `updated_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
                              ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`player_id`),
    CONSTRAINT `fk_pos_player`
        FOREIGN KEY (`player_id`) REFERENCES `nx_players` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  TABLE: nx_player_metadata
--  Dados extras do jogador em formato JSON (texto livre).
--  Exemplos: licencas de conducao, armas, flags de missoes,
--  estado de fome/sede persistido, skin data, etc.
--  Usar LONGTEXT para compatibilidade total MySQL 5.7+
-- ============================================================
CREATE TABLE IF NOT EXISTS `nx_player_metadata` (
    `player_id`     INT(11)    UNSIGNED NOT NULL,
    `meta`          LONGTEXT   NOT NULL DEFAULT '{}',
    `updated_at`    TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP
                               ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`player_id`),
    CONSTRAINT `fk_meta_player`
        FOREIGN KEY (`player_id`) REFERENCES `nx_players` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  TABLE: nx_staff
--  Cargos de staff atribuidos via /setstaff.
--  Cargos possiveis (por ordem de hierarquia):
--  trial, support, mod, admin, developer, co-owner, owner
-- ============================================================
CREATE TABLE IF NOT EXISTS `nx_staff` (
    `id`            INT(11)     UNSIGNED NOT NULL AUTO_INCREMENT,
    `player_id`     INT(11)     UNSIGNED NOT NULL,
    `license`       VARCHAR(64) NOT NULL,
    `cargo`         VARCHAR(32) NOT NULL DEFAULT 'trial',
    `granted_by`    VARCHAR(64) NOT NULL DEFAULT 'console',
    `created_at`    TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP
                                ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_staff_player`  (`player_id`),
    UNIQUE KEY `uq_staff_license` (`license`),
    INDEX      `idx_staff_cargo`  (`cargo`),
    CONSTRAINT `fk_staff_player`
        FOREIGN KEY (`player_id`) REFERENCES `nx_players` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  TABLE: nx_bans
--  Registo de banimentos permanentes e temporarios.
--  expires_at = NULL significa banimento permanente.
--  O loop em server/ban.lua limpa bans expirados de 5 em 5 min.
-- ============================================================
CREATE TABLE IF NOT EXISTS `nx_bans` (
    `id`            INT(11)      UNSIGNED NOT NULL AUTO_INCREMENT,
    `license`       VARCHAR(64)  NOT NULL,
    `reason`        VARCHAR(255) NOT NULL DEFAULT 'Sem motivo especificado.',
    `banned_by`     VARCHAR(64)  NOT NULL DEFAULT 'console',
    `expires_at`    DATETIME     DEFAULT NULL,
    `created_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_ban_license` (`license`),
    INDEX      `idx_ban_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  TABLE: nx_logs
--  Auditoria de todas as acoes criticas de staff.
--  Acoes registadas: ban, unban, setstaff, remstaff,
--  giveitem, givemoney, setjob, kick, etc.
-- ============================================================
CREATE TABLE IF NOT EXISTS `nx_logs` (
    `id`                INT(11)      UNSIGNED NOT NULL AUTO_INCREMENT,
    `action`            VARCHAR(64)  NOT NULL,
    `executor_license`  VARCHAR(64)  NOT NULL DEFAULT 'system',
    `target_license`    VARCHAR(64)  DEFAULT NULL,
    `details`           LONGTEXT     DEFAULT NULL,
    `created_at`        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_log_action`   (`action`),
    INDEX `idx_log_executor` (`executor_license`),
    INDEX `idx_log_target`   (`target_license`),
    INDEX `idx_log_date`     (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  TABLE: nx_vehicles
--  Veiculos persistentes (spawned por staff ou garagem).
--  spawned = 1 -> veiculo esta no mundo
--  spawned = 0 -> veiculo foi removido/servidor reiniciou
--  mods    -> JSON com upgrades aplicados ao veiculo
-- ============================================================
CREATE TABLE IF NOT EXISTS `nx_vehicles` (
    `id`            INT(11)      UNSIGNED NOT NULL AUTO_INCREMENT,
    `plate`         VARCHAR(10)  NOT NULL,
    `net_id`        INT(11)      UNSIGNED DEFAULT NULL,
    `model`         VARCHAR(64)  NOT NULL,
    `owner_id`      INT(11)      UNSIGNED DEFAULT NULL,
    `x`             FLOAT        NOT NULL DEFAULT 0.0,
    `y`             FLOAT        NOT NULL DEFAULT 0.0,
    `z`             FLOAT        NOT NULL DEFAULT 0.0,
    `heading`       FLOAT        NOT NULL DEFAULT 0.0,
    `mods`          LONGTEXT     DEFAULT NULL,
    `spawned`       TINYINT(1)   NOT NULL DEFAULT 0,
    `created_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
                                 ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_plate`     (`plate`),
    INDEX      `idx_veh_owner`   (`owner_id`),
    INDEX      `idx_veh_spawned` (`spawned`),
    CONSTRAINT `fk_veh_owner`
        FOREIGN KEY (`owner_id`) REFERENCES `nx_players` (`id`)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  TABLE: nx_transactions
--  Historico de transferencias de dinheiro entre jogadores.
--  Util para auditoria e resolucao de disputas.
-- ============================================================
CREATE TABLE IF NOT EXISTS `nx_transactions` (
    `id`            INT(11)      UNSIGNED NOT NULL AUTO_INCREMENT,
    `from_license`  VARCHAR(64)  NOT NULL,
    `to_license`    VARCHAR(64)  NOT NULL,
    `money_type`    VARCHAR(16)  NOT NULL DEFAULT 'bank',
    `amount`        BIGINT(20)   UNSIGNED NOT NULL DEFAULT 0,
    `reason`        VARCHAR(128) NOT NULL DEFAULT 'transfer',
    `created_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_tx_from` (`from_license`),
    INDEX `idx_tx_to`   (`to_license`),
    INDEX `idx_tx_date` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  Reativa verificacao de chaves estrangeiras
-- ============================================================
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
--  Verificacao final: lista todas as tabelas criadas
-- ============================================================
SELECT
    TABLE_NAME                              AS 'Tabela',
    COALESCE(TABLE_ROWS, 0)                 AS 'Linhas',
    ENGINE                                  AS 'Motor',
    TABLE_COLLATION                         AS 'Collation',
    CREATE_TIME                             AS 'Criada Em'
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'nx_core'
ORDER BY TABLE_NAME ASC;