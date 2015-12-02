# The GraphQL schema we're going to use
defmodule TestSchema do
  def schema do
    %GraphQL.Schema{
      query: %GraphQL.ObjectType{
        name: "RootQueryType",
        fields: [
          %GraphQL.FieldDefinition{
            name: "greeting",
            type: "String",
            resolve: &TestSchema.greeting/1,
          }
        ]
      }
    }
  end

  def greeting(name: name), do: "Hello, #{name}!"
  def greeting(_), do: greeting(name: "world")
end
