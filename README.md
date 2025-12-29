# WhoknowsElixirMonolith

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
- Run `mix ecto.migrate` to implement the latest migration
- Have the old `whoknows.db` in the repo root and Run `mix migrate_pages`
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Testing

### Unit and Integration Tests
Run Elixir tests with:
```bash
mix test
```

### End-to-End Tests
This project uses Playwright for E2E testing. See [E2E_TESTING.md](E2E_TESTING.md) for complete documentation.

Quick start:
```bash
npm install              # Install Playwright dependencies
npm test                 # Run all E2E tests
npm run test:ui          # Run tests in UI mode
npm run test:headed      # Run tests with visible browser
```

## What happened

1. Erlang was installed first (132 MB) – it is the underlying system that Elixir runs on  
2. Elixir was then installed (7.57 MB) – this is the programming language itself  
3. Both were placed in the correct folders and added to your system's PATH  

You now have access to these commands:

* `elixir` – runs Elixir scripts  
* `mix` – Elixir's build tool (the one we will use for Phoenix)  
* `iex` – interactive Elixir shell  

---

## Environment variables – short explanation

`PATH` is a special environment variable that tells Windows where to look for programs when you type commands in the terminal.

What happened:

* Chocolatey installed Elixir in the folder:  
  `C:\ProgramData\chocolatey\lib\Elixir\tools\bin`
* But it forgot to add this folder to your `PATH` variable  
* So Windows didn’t know where `elixir.exe` was located  
* By running:  

  ```powershell
  $env:PATH += ";C:\ProgramData\chocolatey\lib\Elixir\tools\bin"
  ```
