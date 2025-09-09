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
