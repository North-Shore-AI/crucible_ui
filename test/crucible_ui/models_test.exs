defmodule CrucibleUI.ModelsTest do
  use CrucibleUI.DataCase, async: true

  alias CrucibleUI.Models
  alias CrucibleUI.Models.Model

  describe "list_models/0" do
    test "returns all models" do
      model = insert(:model)
      assert [%Model{id: id}] = Models.list_models()
      assert id == model.id
    end
  end

  describe "list_models_by_base/1" do
    test "returns models with matching base_model" do
      insert(:model, base_model: "gpt-4")
      insert(:model, base_model: "claude-3")

      results = Models.list_models_by_base("gpt-4")
      assert length(results) == 1
      assert hd(results).base_model == "gpt-4"
    end
  end

  describe "get_model!/1" do
    test "returns the model with given id" do
      model = insert(:model)
      assert Models.get_model!(model.id).id == model.id
    end
  end

  describe "get_model_by_name/1" do
    test "returns the model with given name" do
      model = insert(:model, name: "unique-model")
      assert Models.get_model_by_name("unique-model").id == model.id
    end

    test "returns nil when not found" do
      assert Models.get_model_by_name("nonexistent") == nil
    end
  end

  describe "create_model/1" do
    test "creates model with valid data" do
      attrs = %{name: "Test Model", base_model: "gpt-4"}
      assert {:ok, %Model{} = model} = Models.create_model(attrs)
      assert model.name == "Test Model"
      assert model.base_model == "gpt-4"
    end

    test "returns error without name" do
      assert {:error, %Ecto.Changeset{}} = Models.create_model(%{base_model: "gpt-4"})
    end

    test "enforces unique name constraint" do
      insert(:model, name: "duplicate")
      assert {:error, changeset} = Models.create_model(%{name: "duplicate"})
      assert "has already been taken" in errors_on(changeset).name
    end
  end

  describe "update_model/2" do
    test "updates model with valid data" do
      model = insert(:model)
      attrs = %{base_model: "claude-3"}
      assert {:ok, %Model{} = updated} = Models.update_model(model, attrs)
      assert updated.base_model == "claude-3"
    end
  end

  describe "delete_model/1" do
    test "deletes the model" do
      model = insert(:model)
      assert {:ok, %Model{}} = Models.delete_model(model)
      assert_raise Ecto.NoResultsError, fn -> Models.get_model!(model.id) end
    end
  end

  describe "add_checkpoint/2" do
    test "adds checkpoint to model" do
      model = insert(:model, checkpoints: [])
      assert {:ok, %Model{} = updated} = Models.add_checkpoint(model, "/path/to/checkpoint")
      assert updated.checkpoints == ["/path/to/checkpoint"]
    end

    test "appends to existing checkpoints" do
      model = insert(:model, checkpoints: ["/first"])
      assert {:ok, %Model{} = updated} = Models.add_checkpoint(model, "/second")
      assert updated.checkpoints == ["/first", "/second"]
    end
  end
end
