defmodule Verk.Manager.Supervisor do
  @moduledoc false
  use Supervisor

  @doc false
  def start_link, do: Supervisor.start_link(__MODULE__, [], name: __MODULE__)

  # allows commands like `VERK_DEFAULT_QUEUE=2 iex -S mix` to work because othewise the arg would come in as "2" and be ignored
  def to_integer(val) when is_bitstring(val) do
    String.to_integer(val)
  end

  def to_integer(val) do
    val
  end

  @doc false
  def init(_) do
    queues = Confex.get_env(:verk, :queues, [])
             |> Enum.map(fn({k,v}) -> {k, to_integer(v)} end)

    children = for {queue, size} <- queues, do: Verk.Queue.Supervisor.child_spec(queue, size)

    children = [worker(Verk.Manager, [queues], id: Verk.Manager) | children]

    supervise(children, strategy: :rest_for_one)
  end

  @doc false
  def start_child(queue, size \\ 25) when is_atom(queue) and size > 0 do
    Supervisor.start_child(__MODULE__, Verk.Queue.Supervisor.child_spec(queue, size))
  end

  @doc false
  def stop_child(queue) when is_atom(queue) do
    name = Verk.Queue.Supervisor.name(queue)

    case Supervisor.terminate_child(__MODULE__, name) do
      :ok -> Supervisor.delete_child(__MODULE__, name)
      error = {:error, :not_found} -> error
    end
  end
end
