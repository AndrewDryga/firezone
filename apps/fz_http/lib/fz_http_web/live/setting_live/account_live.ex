defmodule FzHttpWeb.SettingLive.Account do
  @moduledoc """
  Handles Account-related things for admins.
  """
  use FzHttpWeb, :live_view

  alias FzHttp.{
    ApiTokens,
    MFA,
    Users
  }

  alias FzHttpWeb.{
    Endpoint,
    Presence
  }

  @live_sessions_topic "notification:session"
  @page_title "Account Settings"
  @page_subtitle "Configure settings related to your Firezone web portal account."

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    Endpoint.subscribe(@live_sessions_topic)

    {:ok,
     socket
     |> assign(:api_token_id, params["api_token_id"])
     |> assign(:subscribe_link, subscribe_link())
     |> assign(:allow_delete, length(Users.list_admins()) > 1)
     |> assign(:api_tokens, ApiTokens.list_api_tokens(socket.assigns.current_user.id))
     |> assign(:changeset, Users.change_user(socket.assigns.current_user))
     |> assign(:methods, MFA.list_methods(socket.assigns.current_user))
     |> assign(:page_title, @page_title)
     |> assign(:page_subtitle, @page_subtitle)
     |> assign(:rules_path, ~p"/rules")
     |> assign(
       :metas,
       get_metas(Presence.list(@live_sessions_topic), socket.assigns.current_user.id)
     )}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"api_token_id" => api_token_id}, _url, socket) do
    {:noreply,
     socket
     |> assign(:api_token_id, api_token_id)}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(:allow_delete, length(Users.list_admins()) > 1)
     |> assign(:api_tokens, ApiTokens.list_api_tokens(socket.assigns.current_user.id))}
  end

  @impl Phoenix.LiveView
  def handle_event("delete_api_token", %{"id" => id}, socket) do
    api_token = ApiTokens.get_api_token!(id)

    if api_token.user_id == socket.assigns.current_user.id do
      {:ok, _deleted} = ApiTokens.delete_api_token(api_token)
    end

    {:noreply,
     socket
     |> assign(:api_tokens, ApiTokens.list_api_tokens(socket.assigns.current_user.id))}
  end

  @impl Phoenix.LiveView
  def handle_event("delete_authenticator", %{"id" => id}, socket) do
    method = MFA.get_method!(id)

    # A user can only delete his/her own MFA method!
    if method.user_id == socket.assigns.current_user.id do
      {:ok, _deleted} = MFA.delete_method(method)
    end

    {:noreply,
     socket
     |> assign(:methods, MFA.list_methods(socket.assigns.current_user))}
  end

  @impl Phoenix.LiveView
  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        %{assigns: %{metas: metas}} = socket
      ) do
    metas =
      (metas ++
         get_metas(joins, socket.assigns.current_user.id)) --
        get_metas(leaves, socket.assigns.current_user.id)

    {:noreply, assign(socket, :metas, metas)}
  end

  defp get_metas(presences, user_id) do
    get_in(presences, [user_id, :metas]) || []
  end

  defp subscribe_link do
    tid = Application.get_env(:fz_http, :telemetry_id)
    "https://www.firezone.dev/contact/sales?utm_source=product&uid=#{tid}"
  end
end
