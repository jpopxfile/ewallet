defmodule AdminAPI.V1.AdminAuth.UserControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.Web.Date
  alias EWalletDB.{Account, AccountUser, User, AuthToken, Role, Membership}
  alias ActivityLogger.System

  @owner_app :some_app

  describe "/user.all" do
    test "returns a list of users and pagination data" do
      response = admin_user_request("/user.all")

      # Asserts return data
      assert response["success"]
      assert response["data"]["object"] == "list"
      assert is_list(response["data"]["data"])

      # Asserts pagination data
      pagination = response["data"]["pagination"]
      assert is_integer(pagination["per_page"])
      assert is_integer(pagination["current_page"])
      assert is_boolean(pagination["is_last_page"])
      assert is_boolean(pagination["is_first_page"])
    end

    test "returns a list of users according to search_term, sort_by and sort_direction" do
      user_1 = insert(:user, %{username: "match_user1"})
      user_2 = insert(:user, %{username: "match_user3"})
      user_3 = insert(:user, %{username: "match_user2"})
      user_4 = insert(:user, %{username: "missed_user1"})

      account = Account.get_master_account()
      {:ok, _} = AccountUser.link(account.uuid, user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account.uuid, user_2.uuid, %System{})
      {:ok, _} = AccountUser.link(account.uuid, user_3.uuid, %System{})
      {:ok, _} = AccountUser.link(account.uuid, user_4.uuid, %System{})

      attrs = %{
        # Search is case-insensitive
        "search_term" => "MaTcH",
        "sort_by" => "username",
        "sort_dir" => "desc"
      }

      response = admin_user_request("/user.all", attrs)
      users = response["data"]["data"]

      assert response["success"]
      assert Enum.count(users) == 3
      assert Enum.at(users, 0)["username"] == "match_user3"
      assert Enum.at(users, 1)["username"] == "match_user2"
      assert Enum.at(users, 2)["username"] == "match_user1"
    end

    test_supports_match_any("/user.all", :admin_auth, :user, :username)
    test_supports_match_all("/user.all", :admin_auth, :user, :username)
  end

  describe "/account.get_users" do
    test "returns a list of users and pagination data" do
      account = Account.get_master_account()
      response = admin_user_request("/account.get_users", %{id: account.id})

      # Asserts return data
      assert response["success"]
      assert response["data"]["object"] == "list"
      assert is_list(response["data"]["data"])

      # Asserts pagination data
      pagination = response["data"]["pagination"]
      assert is_integer(pagination["per_page"])
      assert is_integer(pagination["current_page"])
      assert is_boolean(pagination["is_last_page"])
      assert is_boolean(pagination["is_first_page"])
    end

    test "returns a list of users according to the given account when owned = true" do
      user_1 = insert(:user, %{username: "user_1"})
      user_2 = insert(:user, %{username: "user_2"})
      user_3 = insert(:user, %{username: "user_3"})
      user_4 = insert(:user, %{username: "user_4"})

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account, parent: account_2)

      {:ok, _} = AccountUser.link(account_1.uuid, user_1.uuid, %System{})

      {:ok, _} = AccountUser.link(account_2.uuid, user_2.uuid, %System{})
      {:ok, _} = AccountUser.link(account_2.uuid, user_3.uuid, %System{})
      {:ok, _} = AccountUser.link(account_3.uuid, user_3.uuid, %System{})
      {:ok, _} = AccountUser.link(account_3.uuid, user_4.uuid, %System{})

      attrs = %{
        # Search is case-insensitive
        "id" => account_2.id,
        "owned" => true
      }

      response = admin_user_request("/account.get_users", attrs)
      users = response["data"]["data"]

      assert response["success"]
      assert Enum.count(users) == 2
      assert Enum.any?(users, fn user -> user["username"] == "user_2" end)
      assert Enum.any?(users, fn user -> user["username"] == "user_3" end)
    end

    test "returns a list of users according to the given account" do
      user_1 = insert(:user, %{username: "user_1"})
      user_2 = insert(:user, %{username: "user_2"})
      user_3 = insert(:user, %{username: "user_3"})
      user_4 = insert(:user, %{username: "user_4"})

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account, parent: account_2)

      {:ok, _} = AccountUser.link(account_1.uuid, user_1.uuid, %System{})

      {:ok, _} = AccountUser.link(account_2.uuid, user_2.uuid, %System{})
      {:ok, _} = AccountUser.link(account_2.uuid, user_3.uuid, %System{})
      {:ok, _} = AccountUser.link(account_3.uuid, user_3.uuid, %System{})
      {:ok, _} = AccountUser.link(account_3.uuid, user_4.uuid, %System{})

      attrs = %{
        # Search is case-insensitive
        "id" => account_2.id
      }

      response = admin_user_request("/account.get_users", attrs)
      users = response["data"]["data"]

      assert response["success"]
      assert Enum.count(users) == 3
      assert Enum.any?(users, fn user -> user["username"] == "user_2" end)
      assert Enum.any?(users, fn user -> user["username"] == "user_3" end)
      assert Enum.any?(users, fn user -> user["username"] == "user_4" end)
    end

    test "returns a list of users according to search_term, sort_by and sort_direction" do
      user_1 = insert(:user, %{username: "match_user1"})
      user_2 = insert(:user, %{username: "match_user3"})
      user_3 = insert(:user, %{username: "match_user2"})
      user_4 = insert(:user, %{username: "missed_user1"})

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account, parent: account_2)

      {:ok, _} = AccountUser.link(account_1.uuid, user_1.uuid, %System{})

      {:ok, _} = AccountUser.link(account_2.uuid, user_2.uuid, %System{})
      {:ok, _} = AccountUser.link(account_2.uuid, user_3.uuid, %System{})
      {:ok, _} = AccountUser.link(account_3.uuid, user_3.uuid, %System{})
      {:ok, _} = AccountUser.link(account_3.uuid, user_4.uuid, %System{})

      attrs = %{
        # Search is case-insensitive
        "id" => account_2.id,
        "search_term" => "MaTcH",
        "sort_by" => "username",
        "sort_dir" => "desc"
      }

      response = admin_user_request("/account.get_users", attrs)
      users = response["data"]["data"]

      assert response["success"]
      assert Enum.count(users) == 2
      assert Enum.at(users, 0)["username"] == "match_user3"
      assert Enum.at(users, 1)["username"] == "match_user2"
    end
  end

  describe "/user.get" do
    test "returns an user by the given user's ID" do
      users = insert_list(3, :user)
      # Pick the 2nd inserted user
      target = Enum.at(users, 1)

      account = Account.get_master_account()
      {:ok, _} = AccountUser.link(account.uuid, target.uuid, %System{})

      response = admin_user_request("/user.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "user"
      assert response["data"]["username"] == target.username
    end

    test "returns 'unauthorized' if the given ID was not found" do
      response = admin_user_request("/user.get", %{"id" => "usr_12345678901234567890123456"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end

    test "returns 'unauthorized' if the given ID format is invalid" do
      response = admin_user_request("/user.get", %{"id" => "not_uuid"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end

    test "responds with user data if the user is found by its provider_user_id" do
      inserted_user =
        :user
        |> build(provider_user_id: "provider_id_1")
        |> insert()

      account = Account.get_master_account()
      {:ok, _} = AccountUser.link(account.uuid, inserted_user.uuid, %System{})

      request_data = %{provider_user_id: inserted_user.provider_user_id}
      response = admin_user_request("/user.get", request_data)

      expected = %{
        "version" => @expected_version,
        "success" => true,
        "data" => %{
          "object" => "user",
          "id" => inserted_user.id,
          "socket_topic" => "user:#{inserted_user.id}",
          "provider_user_id" => inserted_user.provider_user_id,
          "username" => inserted_user.username,
          "full_name" => inserted_user.full_name,
          "calling_name" => inserted_user.calling_name,
          "metadata" => %{
            "first_name" => inserted_user.metadata["first_name"],
            "last_name" => inserted_user.metadata["last_name"]
          },
          "encrypted_metadata" => %{},
          "created_at" => Date.to_iso8601(inserted_user.inserted_at),
          "updated_at" => Date.to_iso8601(inserted_user.updated_at),
          "email" => nil,
          "enabled" => inserted_user.enabled,
          "avatar" => %{
            "large" => nil,
            "original" => nil,
            "small" => nil,
            "thumb" => nil
          }
        }
      }

      assert response == expected
    end

    test "responds with an error if user is not found by provider_user_id" do
      expected = %{
        "version" => @expected_version,
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "unauthorized",
          "description" => "You are not allowed to perform the requested operation.",
          "messages" => nil
        }
      }

      request_data = %{provider_user_id: "unknown_id999"}
      response = admin_user_request("/user.get", request_data)

      assert response == expected
    end

    test "responds :invalid_parameter if provider_user_id not given" do
      expected = %{
        "version" => @expected_version,
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "client:invalid_parameter",
          "description" => "Invalid parameter provided.",
          "messages" => nil
        }
      }

      response = admin_user_request("/user.get", %{})

      assert response == expected
    end

    test "responds :invalid_parameter if provider_user_id is nil" do
      expected = %{
        "version" => @expected_version,
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "client:invalid_parameter",
          "description" => "Invalid parameter provided.",
          "messages" => nil
        }
      }

      request_data = %{provider_user_id: nil}
      response = admin_user_request("/user.get", request_data)

      assert response == expected
    end
  end

  describe "/user.create" do
    test "creates and responds with a newly created user if attributes are valid" do
      request_data =
        params_for(
          :user,
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        )

      response = admin_user_request("/user.create", request_data)

      assert response["version"] == @expected_version
      assert response["success"] == true
      assert Map.has_key?(response["data"], "id")

      data = response["data"]
      assert data["object"] == "user"
      assert data["provider_user_id"] == request_data.provider_user_id
      assert data["username"] == request_data.username
      assert data["metadata"] == %{"something" => "interesting"}
      assert data["encrypted_metadata"] == %{"something" => "secret"}

      metadata = data["metadata"]
      assert metadata["first_name"] == request_data.metadata["first_name"]
      assert metadata["last_name"] == request_data.metadata["last_name"]
    end

    test "generates an activity log" do
      request_data =
        params_for(
          :user,
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        )

      timestamp = DateTime.utc_now()

      response = admin_user_request("/user.create", request_data)

      assert response["success"] == true

      user = User.get(response["data"]["id"])
      wallet = User.get_primary_wallet(user)
      account_user = get_last_inserted(AccountUser)

      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 3

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: user,
        target: wallet,
        changes: %{
          "identifier" => "primary",
          "name" => "primary",
          "user_uuid" => user.uuid
        },
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(1)
      |> assert_activity_log(
        action: "insert",
        originator: get_test_admin(),
        target: user,
        changes: %{
          "metadata" => %{"something" => "interesting"},
          "calling_name" => user.calling_name,
          "full_name" => user.full_name,
          "provider_user_id" => user.provider_user_id,
          "username" => user.username
        },
        encrypted_changes: %{
          "encrypted_metadata" => %{"something" => "secret"}
        }
      )

      logs
      |> Enum.at(2)
      |> assert_activity_log(
        action: "insert",
        originator: get_test_admin(),
        target: account_user,
        changes: %{
          "account_uuid" => account_user.account_uuid,
          "user_uuid" => user.uuid
        },
        encrypted_changes: %{}
      )
    end

    test "returns an error if provider_user_id is not provided" do
      request_data = params_for(:user, provider_user_id: "")
      response = admin_user_request("/user.create", request_data)

      assert response["version"] == @expected_version
      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. " <> "`provider_user_id` can't be blank."

      assert response["data"]["messages"] == %{"provider_user_id" => ["required"]}
    end

    test "returns an error if username is not provided" do
      request_data = params_for(:user, username: "")
      response = admin_user_request("/user.create", request_data)

      assert response["version"] == @expected_version
      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. " <> "`username` can't be blank."

      assert response["data"]["messages"] == %{"username" => ["required"]}
    end
  end

  describe "/user.update" do
    test "updates the user if attributes are valid" do
      {:ok, user} = :user |> params_for() |> User.insert()

      # Prepare the update data while keeping only provider_user_id the same
      request_data =
        params_for(:user, %{
          provider_user_id: user.provider_user_id,
          username: "updated_username",
          metadata: %{
            first_name: "updated_first_name",
            last_name: "updated_last_name"
          }
        })

      account = Account.get_master_account()
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

      response = admin_user_request("/user.update", request_data)

      assert response["version"] == @expected_version
      assert response["success"] == true

      data = response["data"]
      assert data["object"] == "user"
      assert data["provider_user_id"] == user.provider_user_id
      assert data["username"] == request_data.username

      metadata = data["metadata"]
      assert metadata["first_name"] == request_data.metadata.first_name
      assert metadata["last_name"] == request_data.metadata.last_name
    end

    test "updates the metadata and encrypted metadata" do
      {:ok, user} = :user |> params_for() |> User.insert()

      account = Account.get_master_account()
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

      request_data =
        params_for(:user, %{
          provider_user_id: user.provider_user_id,
          metadata: %{first_name: "updated_first_name"},
          encrypted_metadata: %{my_secret_stuff: "123"}
        })

      response = admin_user_request("/user.update", request_data)

      assert response["success"] == true
      assert response["data"]["metadata"] == %{"first_name" => "updated_first_name"}
      assert response["data"]["encrypted_metadata"] == %{"my_secret_stuff" => "123"}
    end

    test "does not change the metadata/encrypted_metadata if not sent" do
      user =
        insert(:user, %{
          metadata: %{first_name: "updated_first_name"},
          encrypted_metadata: %{my_secret_stuff: "123"}
        })

      account = Account.get_master_account()
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

      response =
        admin_user_request("/user.update", %{
          provider_user_id: user.provider_user_id,
          username: "new_username"
        })

      assert response["success"] == true
      assert response["data"]["username"] == "new_username"
      assert response["data"]["metadata"] == %{"first_name" => "updated_first_name"}
      assert response["data"]["encrypted_metadata"] == %{"my_secret_stuff" => "123"}
    end

    test "resets the metadata/encrypted_metadata when sending empty hashes" do
      user =
        insert(:user, %{
          metadata: %{first_name: "updated_first_name"},
          encrypted_metadata: %{my_secret_stuff: "123"}
        })

      account = Account.get_master_account()
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

      response =
        admin_user_request("/user.update", %{
          provider_user_id: user.provider_user_id,
          username: "new_username",
          metadata: %{},
          encrypted_metadata: %{}
        })

      assert response["success"] == true
      assert response["data"]["metadata"] == %{}
      assert response["data"]["encrypted_metadata"] == %{}
    end

    test "returns empty metadata when sending nil for metadata/encrypted_metadata" do
      {:ok, user} =
        :user
        |> params_for(%{
          metadata: %{first_name: "updated_first_name"},
          encrypted_metadata: %{my_secret_stuff: "123"}
        })
        |> User.insert()

      account = Account.get_master_account()
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

      response =
        admin_user_request("/user.update", %{
          provider_user_id: user.provider_user_id,
          username: "new_username",
          metadata: nil,
          encrypted_metadata: nil
        })

      assert response["success"] == true
      assert response["data"]["metadata"] == %{}
      assert response["data"]["encrypted_metadata"] == %{}
    end

    test "returns an error if provider_user_id is not provided" do
      request_data = params_for(:user, %{provider_user_id: ""})
      response = admin_user_request("/user.update", request_data)

      assert response["version"] == @expected_version
      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided."
    end

    test "returns an error if user for provider_user_id is not found" do
      request_data = params_for(:user, %{provider_user_id: "unknown_id"})
      response = admin_user_request("/user.update", request_data)

      assert response["version"] == @expected_version
      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end

    test "returns an error if username is not provided" do
      {:ok, user} = :user |> params_for() |> User.insert()

      # ExMachine will remove the param if set to nil.
      request_data =
        params_for(:user, %{
          provider_user_id: user.provider_user_id,
          username: nil
        })

      response = admin_user_request("/user.update", request_data)

      assert response["version"] == @expected_version
      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided."
    end

    test "generates an activity log" do
      {:ok, user} = :user |> params_for() |> User.insert()

      # Prepare the update data while keeping only provider_user_id the same
      request_data =
        params_for(:user, %{
          provider_user_id: user.provider_user_id,
          username: "updated_username",
          metadata: %{
            first_name: "updated_first_name",
            last_name: "updated_last_name"
          }
        })

      account = Account.get_master_account()
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

      timestamp = DateTime.utc_now()

      response = admin_user_request("/user.update", request_data)

      assert response["success"] == true

      user = User.get(response["data"]["id"])

      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: get_test_admin(),
        target: user,
        changes: %{
          "metadata" => %{
            "first_name" => "updated_first_name",
            "last_name" => "updated_last_name"
          },
          "username" => "updated_username",
          "calling_name" => user.calling_name,
          "full_name" => user.full_name
        },
        encrypted_changes: %{}
      )
    end
  end

  describe "/user.enable_or_disable" do
    test "disable a user succeed and disable his tokens given his id" do
      user = insert(:user, %{enabled: true})
      account = Account.get_master_account()
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

      {:ok, token} = AuthToken.generate(user, @owner_app, %System{})
      token_string = token.token
      # Ensure tokens is usable.
      assert AuthToken.authenticate(token_string, @owner_app)

      response =
        admin_user_request("/user.enable_or_disable", %{
          id: user.id,
          enabled: false
        })

      assert response["success"] == true
      assert response["data"]["enabled"] == false
      assert AuthToken.authenticate(token_string, @owner_app) == :token_expired
    end

    test "disable a user succeed and disable his tokens given his provider user id" do
      user = insert(:user, %{enabled: true})
      account = Account.get_master_account()
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

      {:ok, token} = AuthToken.generate(user, @owner_app, %System{})
      token_string = token.token
      # Ensure tokens is usable.
      assert AuthToken.authenticate(token_string, @owner_app)

      response =
        admin_user_request("/user.enable_or_disable", %{
          provider_user_id: user.provider_user_id,
          enabled: false
        })

      assert response["success"] == true
      assert response["data"]["enabled"] == false
      assert AuthToken.authenticate(token_string, @owner_app) == :token_expired
    end

    test "can't disable a user in an account above the current one" do
      master = Account.get_master_account()
      role = Role.get_by(name: "admin")

      admin = get_test_admin()
      {:ok, _m} = Membership.unassign(admin, master, %System{})

      user = insert(:user, %{enabled: true})
      {:ok, _} = AccountUser.link(master.uuid, user.uuid, %System{})

      sub_acc = insert(:account, parent: master, name: "Account 1")
      {:ok, _m} = Membership.assign(admin, sub_acc, role, %System{})

      response =
        admin_user_request("/user.enable_or_disable", %{
          id: user.id,
          enabled: false
        })

      assert response["success"] == false
      assert response["data"]["code"] == "unauthorized"
    end

    test "disable a user that doesn't exist raises an error" do
      response =
        admin_user_request("/user.enable_or_disable", %{
          id: "invalid_id",
          enabled: false
        })

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:id_not_found"

      assert response["data"]["description"] ==
               "There is no user corresponding to the provided id."
    end

    test "disable a user with missing params raises an error" do
      response =
        admin_user_request("/user.enable_or_disable", %{
          enabled: false
        })

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `id` or `provider_user_id` is required."
    end

    test "generates an activity log" do
      user = insert(:user, %{enabled: true})
      account = Account.get_master_account()
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/user.enable_or_disable", %{
          id: user.id,
          enabled: false
        })

      assert response["success"] == true

      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: get_test_admin(),
        target: user,
        changes: %{
          "enabled" => false
        },
        encrypted_changes: %{}
      )
    end
  end
end
