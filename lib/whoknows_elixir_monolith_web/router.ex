defmodule WhoknowsElixirMonolithWeb.Router do
  use WhoknowsElixirMonolithWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WhoknowsElixirMonolithWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug WhoknowsElixirMonolithWeb.UserAuth, :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", WhoknowsElixirMonolithWeb do
    pipe_through :browser

    get "/", SearchController, :index
    get "/register", UserController, :register
    get "/login", UserController, :login
    get "/weather", WeatherController, :weather
  end

  # Other scopes may use custom stacks.
   scope "/api", WhoknowsElixirMonolithWeb.Api do
     pipe_through :api

     get "/search", SearchController, :search
     post "/register", UserController, :register
     post "/login", UserController, :login
     get "/logout", UserController, :logout
   end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:whoknows_elixir_monolith, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: WhoknowsElixirMonolithWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
