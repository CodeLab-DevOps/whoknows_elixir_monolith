# WhoknowsElixirMonolith

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## What happened
1. Erlang was installed first (132 MB) – it is the underlying system that Elixir runs on  
2. Elixir was then installed (7.57 MB) – this is the programming language itself  
3. Both were placed in the correct folders and added to your system's PATH  

You now have access to these commands:
- `elixir` – runs Elixir scripts  
- `mix` – Elixir's build tool (the one we will use for Phoenix)  
- `iex` – interactive Elixir shell  

---

## Environment variables – short explanation
`PATH` is a special environment variable that tells Windows where to look for programs when you type commands in the terminal.

What happened:
- Chocolatey installed Elixir in the folder:  
  `C:\ProgramData\chocolatey\lib\Elixir\tools\bin`
- But it forgot to add this folder to your `PATH` variable  
- So Windows didn’t know where `elixir.exe` was located  
- By running:  
  ```powershell
  $env:PATH += ";C:\ProgramData\chocolatey\lib\Elixir\tools\bin"

## Database Setup Options

You have two options for running PostgreSQL during development:

### Option 1: Docker (Recommended)

1. Make sure you have Docker Desktop installed
2. Start the database:
   ```bash
   docker-compose up -d postgres
   ```
3. Set up the database:
   ```bash
   mix ecto.create
   mix ecto.migrate
   ```
4. Start your Phoenix server:
   ```bash
   mix phx.server
   ```
5. To stop the database when done:
   ```bash
   docker-compose down
   ```

### Option 2: Local PostgreSQL Installation

If you prefer to install PostgreSQL locally, make sure you have:
- PostgreSQL installed and running
- A database user `postgres` with password `postgres`
- Create the database: `whoknows_elixir_monolith_dev`

## No Environment Variables Needed!

The app is configured to use `postgres/postgres` as the default username/password for development. No environment variables need to be set - everything works out of the box with Docker.

## Useful Docker Commands

- **Start database**: `docker-compose up -d postgres`
- **Stop database**: `docker-compose down`
- **View database logs**: `docker-compose logs postgres`
- **Connect to database directly**: `docker exec -it whoknows_postgres_dev psql -U postgres -d whoknows_elixir_monolith_dev`
- **Reset database**: `mix ecto.reset`
- **Check if running**: `docker ps`