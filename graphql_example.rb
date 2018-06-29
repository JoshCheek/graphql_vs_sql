# This code will wire GraphQL to our data.
# We're using a struct for simplicity, a real implementation would probably be a database call
# Our SQL implementation must be equally able to wire SQL queries to this code
Post = Struct.new :id, :title, :body, :comments
RESOLVER = -> (obj, args, ctx) {
  Post.new args[:id], 'a', 'b', ["a"]
}

# ========== Now we wire up GraphQL ==========
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
Schema = GraphQL::Schema.define do
  query QueryRoot
end

# An example query
Schema.execute(<<~GRAPHQL).to_h
query {
  post(id: 123) {
    id
    title
  }
}
GRAPHQL
# => {"data"=>{"post"=>{"id"=>123, "title"=>"a"}}}
