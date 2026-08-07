
docker compose up -d

-d - detached mode чтобы пользоваться терминалом дальше


docker compose down


# смотреть логи

docker compose logs -f backend

docker compose logs -f

docker compose logs -f --tail=100 backend


# ребилд

docker compose up --build

# вход в psql

docker compose exec database psql -U heat -d heat

# все таблицы текущей схемы

\dt

# структура конкретной таблицы

\d users

# выйти из psql

\q

# чтобы удалить volume (данные бд)

docker compose down -v

docker volume rm heat_postgres_data
