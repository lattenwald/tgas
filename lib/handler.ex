defmodule Tgas.Handler do
  @outdated 60
  # TODO: move to config
  @spam Application.get_env(:tgas, :spam_chat)

  use GenServer

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    send(self(), :init)
    {:ok, nil}
  end

  def handle_info(:init, state) do
    Logger.warn("Registering handler: #{__MODULE__}")
    Tgas.Session.register_handler(self())
    {:noreply, state}
  end

  def handle_info({:incoming, data}, state) do
    {_, type} = List.keyfind(data, "@type", 0, {nil, nil})

    if type == "error" do
      Logger.error("error from tdlib: #{inspect(data)}")
    else
      send(self(), {:incoming, type, data})
    end

    {:noreply, state}
  end

  def handle_info(
        {:incoming, "updateNewMessage", data},
        state
      ) do
    data = data |> list_to_map |> Map.delete("@extra")

    with date when not is_nil(date) <- data |> get_in(["message", "date"]),
         true <- :os.system_time(:seconds) - @outdated < date,
         message <- data["message"],
         true <- message["chat_id"] == message["sender_user_id"],
         "messagePhoto" <- get_in(message, ["content", "@type"]),
         user_id <- message["sender_user_id"],
         user <-
           Tgas.Session.send_sync(%{"@type" => "getUser", "user_id" => user_id})
           |> list_to_map
           |> Map.delete("@extra"),
         false <- user["is_contact"],
         false <- user["is_support"],
         "userTypeRegular" <- get_in(user, ["type", "@type"]),
         history <-
           list_to_map(
             Tgas.Session.send_sync(%{
               "@type" => "getChatHistory",
               "chat_id" => user_id,
               "offset" => 0,
               "limit" => 5
             })
           ),
         1 <- history["total_count"] do
      Logger.info(fn -> "message: #{inspect(data)}" end)
      Logger.info(fn -> "from user: #{inspect(user)}" end)

      save_to_spam(user, message["id"])

      Tgas.Session.send_sync(%{
        "@type" => "deleteChatHistory",
        "chat_id" => user_id,
        "remove_from_chat_list" => true,
        "revoke" => true
      })

      :ok
    else
      _ -> :ok
    end

    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def list_to_map(kw = [{_, _} | _]) do
    kw |> Enum.map(fn item -> list_to_map(item) end) |> Enum.into(%{})
  end

  def list_to_map(kw) when is_list(kw) do
    kw |> Enum.map(fn item -> list_to_map(item) end)
  end

  def list_to_map({key, val}) do
    {key, list_to_map(val)}
  end

  def list_to_map(other) do
    other
  end

  def utf16_len(text), do: utf16_len(text, 0)
  defp utf16_len(<<>>, len), do: len
  defp utf16_len(<<_::utf16, rest::binary>>, len), do: utf16_len(rest, len + 2)
  defp utf16_len(<<_::utf8, rest::binary>>, len), do: utf16_len(rest, len + 1)

  defp save_to_spam(_, _) when is_nil(@spam), do: :ok

  defp save_to_spam(user, msg_id) do
    chat_id = user["id"]

    forwarded =
      list_to_map(
        Tgas.Session.send_sync(%{
          "@type" => "forwardMessages",
          "chat_id" => @spam,
          "from_chat_id" => chat_id,
          "message_ids" => [msg_id]
        })
      )
    :timer.sleep(200)

    msg_id = hd(forwarded["messages"])["id"]

    spawn(fn ->
      text = Poison.encode!(user, pretty: true)

      Tgas.Session.send_sync(%{
        "@type" => "sendMessage",
        "chat_id" => @spam,
        "reply_to_message_id" => msg_id,
        "input_message_content" => %{
          "@type" => "inputMessageText",
          "text" => %{
            "@type" => "formattedText",
            "text" => text,
            "entities" => [
              %{
                "@type" => "textEntity",
                "offset" => 0,
                "length" => utf16_len(text),
                "type" => %{"@type" => "textEntityTypePreCode"}
              }
            ]
          }
        }
      })
    end)
  end
end
