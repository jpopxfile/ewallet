# credo:disable-for-this-file
defmodule EWalletDB.Repo.Seeds.SettingSeed do
  alias EWalletConfig.{Config, Setting}

  @argsline_desc """
  The base URL is needed for various operators in the eWallet. It will be saved in the
  settings during the seeding process and you will be able to update it later.
  """

  def seed do
    [
      run_banner: "Seeding the settings",
      argsline: get_argsline()
    ]
  end

  defp get_argsline do
    case Application.get_env(:ewallet_db, "base_url") do
      nil ->
        [
          {:title, "Enter the base URL for this instance of the ewallet (e.g. https://myewallet.com)."},
          {:text, @argsline_desc},
          {:input, {:text, :base_url, "Base URL", System.get_env("BASE_URL") || "http://localhost:4000"}}
        ]
      _setting ->
        []
    end
  end

  def run(writer, args) do
    Config.get_default_settings()
    |> put_in(["base_url", :value], args[:base_url])
    |> put_in(["redirect_url_prefixes", :value], [args[:base_url]])
    |> Enum.each(fn data->
      run_with(writer, data)
    end)
  end

  defp run_with(writer, {key, data}) do
    case Config.get_setting(key) do
      nil ->
        data
        |> Map.put(:originator, %EWalletDB.Seeder{})
        |> Config.insert()
        |> case do
          {:ok, setting} ->
            writer.success("""
              Key      : #{setting.key}
              Value    : #{setting.value}
              Position : #{setting.position}
            """)
          {:error, changeset} ->
            writer.error("  The setting could not be inserted:")
            writer.print_errors(changeset)
          _ ->
            writer.error("  The setting could not be inserted:")
            writer.error("  Unknown error.")
        end
      setting ->
        case sync_position(key, setting, data) do
          {:ok, old_position, new_position} ->
            writer.warn("""
              Key      : #{setting.key}
              Value    : #{setting.value}
              Position : #{old_position} -> #{new_position}
            """)

          {:error, changeset} ->
            writer.error("  The setting's position could not be synchronized:")
            writer.print_errors(changeset)

          nil ->
            writer.warn("""
              Key      : #{setting.key}
              Value    : #{setting.value}
              Position : #{setting.position}
            """)
        end
    end
  end

  defp sync_position(key, %{position: old_pos}, %{position: new_pos}) when is_integer(old_pos) and is_integer(new_pos) and old_pos != new_pos do
    case Setting.update(key, %{position: new_pos}) do
      {:ok, _} -> {:ok, old_pos, new_pos}
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp sync_position(_, _, _), do: nil
end
