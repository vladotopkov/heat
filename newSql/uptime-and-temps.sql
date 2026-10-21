-- Adminer 5.5.1 PostgreSQL 17.10 dump

CREATE DATABASE "heatLoss";
\connect "heatLoss";

CREATE TABLE "public"."temperatures" (
    "id" bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    "heat_network_id" bigint NOT NULL,
    "month" date NOT NULL,
    "supply_t" numeric(6,2) NOT NULL,
    "return_t" numeric(6,2) NOT NULL,
    "ground_t" numeric(6,2) NOT NULL,
    CONSTRAINT "temperatures_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE UNIQUE INDEX temperatures_heat_network_id_month_key ON public.temperatures USING btree (heat_network_id, month);


CREATE TABLE "public"."up_time" (
    "id" bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    "heat_network_id" bigint NOT NULL,
    "month" date NOT NULL,
    "hours_per_month" integer NOT NULL,
    CONSTRAINT "up_time_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "up_time_hours_per_month_check" CHECK (((hours_per_month >= 0) AND (hours_per_month <= 744)))
)
WITH (oids = false);

CREATE UNIQUE INDEX up_time_heat_network_id_month_key ON public.up_time USING btree (heat_network_id, month);


ALTER TABLE ONLY "public"."temperatures" ADD CONSTRAINT "temperatures_heat_network_id_fkey" FOREIGN KEY (heat_network_id) REFERENCES "public"."HeatNetwork"(id) ON DELETE CASCADE;

ALTER TABLE ONLY "public"."up_time" ADD CONSTRAINT "up_time_heat_network_id_fkey" FOREIGN KEY (heat_network_id) REFERENCES "public"."HeatNetwork"(id) ON DELETE CASCADE;

-- 2026-08-27 07:34:33 UTC
