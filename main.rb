# ===== Common Code =====
# We'll show that we can wire this resolver into a GraphQL API and a SQL API
RESOLVER = -> (obj, args, ctx) {
  Post.new args[:id], 'a', 'b', ["a"]
}

# We're using a struct for simplicity, a real implementation would likely be a database call.
Post = Struct.new :id, :title, :body, :comments


# ===== GraphQL =====
require_relative 'wire_up_graphql'
$graphql.execute(<<~GRAPHQL).to_h
query {
  post(id: 123) {
    id
    title
  }
}
GRAPHQL
# => {"data"=>{"post"=>{"id"=>123, "title"=>"a"}}}


# ===== SQL =====
require_relative 'wire_up_sql'
$sql.execute 'select id, title from posts where id = 123'
# => #<struct Post id=123, title="a", body="b", comments=["a"]>
