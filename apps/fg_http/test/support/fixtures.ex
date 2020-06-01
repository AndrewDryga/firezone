defmodule FgHttp.Fixtures do
  @moduledoc """
  Convenience helpers for inserting records
  """
  alias FgHttp.{Devices, PasswordResets, Repo, Sessions, Users, Users.User}

  def user(attrs \\ %{}) do
    case Repo.get_by(User, email: "test") do
      nil ->
        attrs =
          attrs
          |> Enum.into(%{email: "test", password: "test", password_confirmation: "test"})

        {:ok, user} = Users.create_user(attrs)
        user

      %User{} = user ->
        user
    end
  end

  def device(attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{user_id: user().id})
      |> Enum.into(%{public_key: "foobar", ifname: "wg0", name: "factory"})

    {:ok, device} = Devices.create_device(attrs)
    device
  end

  def session(_attrs \\ %{}) do
    {:ok, session} = Sessions.create_session(%{email: user().email, password: "test"})
    session
  end

  def password_reset(attrs \\ %{}) do
    email = user().email

    create_attrs = Map.merge(attrs, %{email: email})

    {:ok, password_reset} =
      PasswordResets.get_password_reset!(email: email)
      |> PasswordResets.create_password_reset(create_attrs)

    password_reset
  end
end
