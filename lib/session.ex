defmodule Tgas.Session do
  use Supervisor
  require Logger

  @session :tgas

  def start_link(nil) do
    Supervisor.start_link(
      __MODULE__,
      nil,
      name: __MODULE__
    )
  end

  def init(_) do
    api_id = Application.fetch_env!(:tdlib, :api_id)
    api_hash = Application.fetch_env!(:tdlib, :api_hash)
    db_dir = Application.fetch_env!(:tdlib, :db)

    tdlib_spec = %{
      id: :tdlib,
      start:
        {:tdlib, :start_link,
         [
           {:local, @session},
           [api_id: api_id, api_hash: api_hash, database_directory: db_dir]
         ]}
    }


    children = [tdlib_spec, {Tgas.Handler, nil}]

    opts = [strategy: :rest_for_one]

    getMe()

    Supervisor.init(children, opts)
  end

  def getMe() do
    ## TODO should do this right after authorized in tdlib, without random timeouts
    spawn(fn ->
      :timer.sleep(1000)
      request = %{"@type" => "getMe"}
      me = send_sync(request)
      {_, id} = List.keyfind(me, "id", 0)
      Logger.info(fn -> "getMe id:#{id}" end)
    end)
  end

  def send_sync(request) do
    request = request |> Enum.into([])
    :tdlib.send_sync(@session, request)
  end

  def register_handler(handler), do: :tdlib.register_handler(@session, handler)
  def send(request), do: :tdlib.send(@session, request)
  def execute(request), do: :tdlib.execute(@session, request)
  def phone_number(phone_number), do: :tdlib.phone_number(@session, phone_number)
  def auth_code(code), do: :tdlib.auth_code(@session, code)
  def auth_password(password), do: :tdlib.auth_password(@session, password)

end
