require 'graphql'

# In GraphQL, we create the types independently from anything else
PostType = GraphQL::ObjectType.define do
  name             "Post"
  description      "A blog post"
  field :id,       !types.Int # the bang means "non nullable"
  field :title,    !types.String
  field :body,     !types.String
  field :comments, types[!types.String]
end

# This is like a router, it vets the queries and hands them to the resolver
QueryRoot = GraphQL::ObjectType.define do
  name "Query"
  description "The query root of this schema"

  field :post do
    type PostType
    argument :id, !types.Int # the query needs to include the id, it can't be nil
    resolve RESOLVER
  end
end

# This composes the toplevel things, though we only have one
$graphql = GraphQL::Schema.define do
  query QueryRoot
end
