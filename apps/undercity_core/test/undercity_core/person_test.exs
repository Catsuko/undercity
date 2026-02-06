defmodule UndercityCore.PersonTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Person

  describe "new/1" do
    test "creates a person with the given name" do
      person = Person.new("Grimshaw")

      assert person.name == "Grimshaw"
    end

    test "generates a unique id" do
      person1 = Person.new("Grimshaw")
      person2 = Person.new("Grimshaw")

      assert person1.id != person2.id
    end
  end
end
