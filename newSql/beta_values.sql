-- Adminer 5.5.1 PostgreSQL 17.10 dump

CREATE DATABASE "heatLoss";
\connect "heatLoss";

CREATE TABLE "public"."beta_values" (
    "id" bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    "project_date_from" date,
    "project_date_to" date,
    "laying_type" character varying(50),
    "underground_laying_type" character varying(50),
    "support_type" character varying(50),
    "nominal_bore_from_mm" numeric,
    "nominal_bore_to_mm" numeric,
    "pipe_type" character varying(50),
    "object_kind" character varying(50),
    "beta" numeric(5,2) NOT NULL,
    "note" text,
    CONSTRAINT "beta_values_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

INSERT INTO "beta_values" ("id", "project_date_from", "project_date_to", "laying_type", "underground_laying_type", "support_type", "nominal_bore_from_mm", "nominal_bore_to_mm", "pipe_type", "object_kind", "beta", "note") VALUES
(1,	NULL,	'1989-12-31',	'UNDERGROUND',	'NON_CHANNEL',	NULL,	NULL,	NULL,	NULL,	'PIPELINE',	1.15,	'Таблица 5.2, п.1.1'),
(2,	NULL,	'1989-12-31',	'UNDERGROUND',	'CHANNEL',	NULL,	NULL,	NULL,	NULL,	'PIPELINE',	1.20,	'Таблица 5.2, п.1.2'),
(3,	NULL,	'1989-12-31',	'OPEN_AIR',	NULL,	NULL,	NULL,	NULL,	NULL,	'PIPELINE',	1.25,	'Таблица 5.2, п.1.3'),
(4,	NULL,	'1989-12-31',	'TUNNEL',	NULL,	NULL,	NULL,	NULL,	NULL,	'PIPELINE',	1.25,	'Таблица 5.2, п.1.3'),
(5,	NULL,	'1989-12-31',	'ROOM',	NULL,	NULL,	NULL,	NULL,	NULL,	'PIPELINE',	1.25,	'Таблица 5.2, п.1.3'),
(6,	NULL,	'1989-12-31',	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	'EQUIPMENT',	1.10,	'Таблица 5.2, п.1.4'),
(7,	'1990-01-01',	'2009-12-31',	NULL,	NULL,	'MOVABLE',	NULL,	150,	NULL,	'PIPELINE',	1.20,	'Таблица 5.2, п.2.1.1, DN < 150'),
(8,	'1990-01-01',	'2009-12-31',	NULL,	NULL,	'MOVABLE',	150,	NULL,	NULL,	'PIPELINE',	1.15,	'Таблица 5.2, п.2.1.1, DN >= 150'),
(9,	'1990-01-01',	'2009-12-31',	NULL,	NULL,	'SUSPENDED',	NULL,	NULL,	NULL,	'PIPELINE',	1.05,	'Таблица 5.2, п.2.1.2'),
(10,	'1990-01-01',	'2009-12-31',	'UNDERGROUND',	'NON_CHANNEL',	NULL,	NULL,	NULL,	NULL,	'PIPELINE',	1.15,	'Таблица 5.2, п.2.2'),
(11,	'1990-01-01',	'2009-12-31',	NULL,	NULL,	NULL,	NULL,	NULL,	'PI',	'PIPELINE',	1.15,	'Таблица 5.2, п.2.2'),
(12,	'1990-01-01',	'2009-12-31',	NULL,	NULL,	NULL,	NULL,	NULL,	'GPI',	'PIPELINE',	1.15,	'Таблица 5.2, п.2.2'),
(13,	'1990-01-01',	'2009-12-31',	NULL,	NULL,	NULL,	NULL,	NULL,	'GSI',	'PIPELINE',	1.15,	'Таблица 5.2, п.2.2'),
(14,	'1990-01-01',	'2009-12-31',	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	'EQUIPMENT',	1.10,	'Таблица 5.2, п.2.3'),
(15,	'2010-01-01',	NULL,	NULL,	NULL,	'MOVABLE',	NULL,	150,	NULL,	'PIPELINE',	1.20,	'Таблица 5.2, п.3.1.1, DN < 150'),
(16,	'2010-01-01',	NULL,	NULL,	NULL,	'MOVABLE',	150,	NULL,	NULL,	'PIPELINE',	1.15,	'Таблица 5.2, п.3.1.1, DN >= 150'),
(17,	'2010-01-01',	NULL,	NULL,	NULL,	'SUSPENDED',	NULL,	NULL,	NULL,	'PIPELINE',	1.05,	'Таблица 5.2, п.3.1.2'),
(18,	'2010-01-01',	NULL,	'UNDERGROUND',	'NON_CHANNEL',	NULL,	NULL,	NULL,	NULL,	'PIPELINE',	1.00,	'Таблица 5.2, п.3.2'),
(19,	'2010-01-01',	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	'PI',	'PIPELINE',	1.00,	'Таблица 5.2, п.3.2'),
(20,	'2010-01-01',	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	'GPI',	'PIPELINE',	1.00,	'Таблица 5.2, п.3.2'),
(21,	'2010-01-01',	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	'GSI',	'PIPELINE',	1.00,	'Таблица 5.2, п.3.2'),
(22,	'2010-01-01',	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	'EQUIPMENT',	1.10,	'Таблица 5.2, п.3.3');

-- 2026-08-26 10:12:05 UTC
