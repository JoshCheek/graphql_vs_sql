require_relative 'lib'

$sql = Sql.new

# This is just a proof of concept, so I'm declaring the type (table)
# in the same statement as the resolver, but I could obviously separate them, too
$sql.define type: <<-SQL, resolve: RESOLVER # ~> NameError: uninitialized constant RESOLVER
create table posts (
  id          int primary key,
  name        text,
  description text,
  title       text not null,
  body        text not null,
  comments    text[]
);
SQL
