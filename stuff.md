## Get list of last 100 chat ids, identified by chat title

    iex> chat_ids = Tgas.Handler.list_to_map(Tgas.Session.send_sync %{"@type" => "getChats", "limit" => 100, "offset_order" => 9223372036854775807})["chat_ids"]
    iex> chat_ids |> Enum.map(fn chat_id -> {chat_id, Tgas.Handler.list_to_map(Tgas.Session.send_sync %{"@type" => "getChat", "chat_id" => chat_id})["title"]} end)
