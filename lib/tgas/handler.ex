defmodule Tgas.Handler do
  @outdated 60

  use GenServer

  require Logger

  defstruct on_sent: %{}

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    send(self(), :init)
    {:ok, %__MODULE__{}}
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
        state = %{on_sent: on_sent}
      ) do
    data = data |> list_to_map |> Map.delete("@extra")

    newstate =
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
        Logger.info(fn -> "message: #{message["id"]}" end)
        Logger.info(fn -> "from user: #{user_id}" end)

        new_on_sent =
          case save_to_spam(user, message["id"]) do
            {on_sent_msg_id, on_sent_reaction} ->
              Map.put(on_sent, on_sent_msg_id, on_sent_reaction)

            _ ->
              on_sent
          end

        Tgas.Session.send(%{
          "@type" => "deleteChatHistory",
          "chat_id" => user_id,
          "remove_from_chat_list" => true,
          "revoke" => true
        })

        %{state | on_sent: new_on_sent}
      else
        _ -> state
      end

    {:noreply, newstate}
  end

  def handle_info(
        {:incoming, type = "updateMessageSendSucceeded", data},
        state = %{on_sent: on_sent}
      ) do
    Logger.debug(fn -> "#{type} #{inspect(data)}" end)
    data = data |> list_to_map |> Map.delete("@extra")

    with {:ok, old_id} <- Map.fetch(data, "old_message_id"),
         {:ok, reaction} <- Map.fetch(on_sent, old_id) do
      Logger.info(fn -> "#{type} old_message_id:#{old_id} has reaction" end)
      spawn(fn -> reaction.(data) end)
      {:noreply, %{state | on_sent: Map.delete(on_sent, old_id)}}
    else
      _ -> {:noreply, state}
    end
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

  defp utf16_len(<<char::utf8, rest::binary>>, len) do
    size = trunc(byte_size(<<char::utf16>>) / 2)
    utf16_len(rest, len + size)
  end

  defp save_to_spam(user, msg_id) do
    case Application.get_env(:tgas, :spam_chat) do
      nil ->
        nil

      spam_chat ->
        chat_id = user["id"]

        forwarded =
          list_to_map(
            Tgas.Session.send_sync(%{
              "@type" => "forwardMessages",
              "chat_id" => spam_chat,
              "from_chat_id" => chat_id,
              "message_ids" => [msg_id]
            })
          )

        msg_id = hd(forwarded["messages"])["id"]
        Logger.info(fn -> "forwarded: #{msg_id}" end)

        reaction = fn
          %{"message" => %{"id" => msg_id}} ->
            text = Poison.encode!(user, pretty: true)

            reply =
              Tgas.Session.send_sync(%{
                "@type" => "sendMessage",
                "chat_id" => spam_chat,
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

            Logger.info(fn -> "sent user info about #{user["id"]}" end)
        end

        {msg_id, reaction}
    end
  end
end
