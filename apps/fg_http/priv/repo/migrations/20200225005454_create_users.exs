defmodule FgHttp.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string
      add :confirmed_at, :utc_datetime
      add :password_hash, :string
      add :last_signed_in_at, :utc_datetime
      add :reset_token, :string
      add :reset_sent_at, :utc_datetime
      add :reset_consumed_at, :utc_datetime

      timestamps()
    end

    create unique_index(:users, [:email])
    create index(:users, [:reset_token, :reset_sent_at, :reset_consumed_at])
    create index(:users, [:confirmed_at])
  end
end
