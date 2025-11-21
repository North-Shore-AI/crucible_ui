defmodule CrucibleUI.Repo do
  use Ecto.Repo,
    otp_app: :crucible_ui,
    adapter: Ecto.Adapters.Postgres
end
