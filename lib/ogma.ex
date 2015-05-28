defmodule Ogma do
  use GenServer

  defmodule State do
    defstruct pid_to_topics: HashDict.new
  end

  def start_link() do
    GenServer.start_link(__MODULE__, :na, [name: __MODULE__])
  end

  def init(:na) do
    {:ok, %State{}}
  end

  def subscribe(topic) do
    GenServer.call(__MODULE__, {:subscribe, topic, self})
  end

  def unsubscribe(topic) do
    GenServer.cast(__MODULE__, {:unsubscribe, topic, self})
  end

  def publish(topic, message) do
    GenServer.cast(__MODULE__, {:publish, topic, message})
  end

  def handle_call({:subscribe, topic, pid}, _from, s) do
    :pg2.create(topic)
    case :pg2.get_members(topic) do
      {:error, error} ->
        {:stop, error, s}
      pids ->
        unless pid in pids do
          case HashDict.fetch(s.pid_to_topics, pid) do
            {:ok, topics} ->
              :pg2.join(topic, pid)
              {:reply, :ok, %{s | pid_to_topics: HashDict.put(s.pid_to_topics, pid, [topic|topics])}}
            :error ->
              :pg2.join(topic, pid)
              {:reply, :ok, %{s | pid_to_topics: HashDict.put(s.pid_to_topics, pid,[topic])}}
          end
      end
    end
  end

  def handle_cast({:unsubscribe, topic, pid}, s) do
    case :pg2.leave(topic, pid) do
      {:error, _} ->
        {:noreply, s}
      :ok ->
        case HashDict.fetch(s.pid_to_topics, pid) do
          {:ok, topics} ->
            case List.delete(topics, topic) do
              [] ->
                {:noreply, %{s | pid_to_topics: HashDict.drop(s.pid_to_topics, [pid])}}
              topics ->
                {:noreply, %{s | pid_to_topics: HashDict.put(s.pid_to_topics, pid, topics)}}
            end
          :error ->
            {:noreply, s}
        end
    end
  end

  def handle_cast({:publish, topic, message}, s) do
    case :pg2.get_members(topic) do
      {:error, _} ->
        {:noreply, s}
      pids ->
        for pid <- pids do
          send(pid, message)
      end #@todo: report indentation error on alchemist
         {:noreply, s}
    end
  end

end
