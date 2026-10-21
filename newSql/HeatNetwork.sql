-- Adminer 5.5.1 PostgreSQL 17.10 dump

CREATE DATABASE "heatLoss";
\connect "heatLoss";

CREATE SEQUENCE "public"."HeatNetwork_id_seq" INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 2 CACHE 1;

CREATE TABLE "public"."HeatNetwork" (
    "id" bigint DEFAULT nextval('public."HeatNetwork_id_seq"') NOT NULL,
    "name" text NOT NULL,
    "project_supply_temperature_c" numeric(6,2),
    "project_return_temperature_c" numeric(6,2),
    "project_ground_temperature_c" numeric(6,2),
    CONSTRAINT "HeatNetwork_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

INSERT INTO "HeatNetwork" ("id", "name", "project_supply_temperature_c", "project_return_temperature_c", "project_ground_temperature_c") VALUES
(1,	'Еремичи',	95.00,	70.00,	9.60);

-- 2026-08-27 10:17:25 UTC
