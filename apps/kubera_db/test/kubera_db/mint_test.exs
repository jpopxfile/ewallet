defmodule KuberaDB.MintTest do
  use KuberaDB.SchemaCase
  alias KuberaDB.Mint

  describe "Mint factory" do
    test_has_valid_factory Mint
  end

  describe "insert/1" do
    test_insert_generate_uuid Mint, :id
    test_insert_generate_timestamps Mint
    test_insert_prevent_blank Mint, :amount
    test_insert_prevent_blank Mint, :minted_token_id
  end
end
