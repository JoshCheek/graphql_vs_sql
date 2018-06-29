# This code will wire Sql to our data.
# We're using a struct for simplicity, a real implementation would probably be a database call
# Our SQL is equally able to wire SQL queries to this code
Post = Struct.new :id, :title, :body, :comments
RESOLVER = -> (obj, args, ctx) {
  Post.new args[:id], 'a', 'b', ["a"]
}

# ========== Now we wire up Sql ==========
require_relative 'lib'

sql = Sql.new

# This is just a proof of concept, so I'm declaring the type (table)
# in the same statement as the resolver, but I could obviously separate them, too
sql.define type: <<-SQL, resolve: RESOLVER
create table posts (
  id          int primary key,
  name        text,
  description text,
  title       text not null,
  body        text not null,
  comments    text[]
);
SQL

# An example query
sql.execute 'select id, title from posts where id = 123'
# => #<struct Post id=123, title="a", body="b", comments=["a"]>
