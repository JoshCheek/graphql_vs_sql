GraphQL vs SQL
==============

I asked on [Twitter](https://twitter.com/josh_cheek/status/1012490394683224064)
why GraphQL didn't just roll with an existing query language like SQL or Cypher.

I think people misunderstood the question as suggesting we should
give clients query access to the database. That wasn't what I was asking.

If they want to map a query language to app code, then why not choose an existing
query language that everyone already knows? Just because it's SQL doesn't mean it's
implemented by a relational database, it's "Structured Query Language", not
"Relational Database Query Language". [DES](http://des.sourceforge.net), for
example, allows you to query it with SQL, Datalog, and Relational Algebra,
AND it delegates storage to an arbitrary backend (eg the actual database).


Proof of Concept
----------------

To illustrate what I mean, I created a proof of concept. It has a very similar
interface to GraphQL, but it uses SQL as the query language.

The entry point is `main.rb`, which begins by defining a `Post` structure that
represents the data we might query from our database. Then it defines a `RESOLVER`,
the lambda that we will provide to connect a query for a post to our Post structure.

```ruby
RESOLVER = -> (obj, args, ctx) { Post.new args[:id], 'a', 'b', ["a"] }
Post = Struct.new :id, :title, :body, :comments
```

Next, we'll load the code that tells GraphQL about our types and wires our
resolver into place. Then we'll query the GraphQL schema we created.
Unsurprisingly, GraphQL was able to map the query to the resolver, provide
the id of `123` in arguments, and the resolver returned a post with that id.

```ruby
require_relative 'wire_up_graphql'
$graphql.execute('query { post(id: 123) { id title } }').to_h
# => {"data"=>{"post"=>{"id"=>123, "title"=>"a"}}}
```

So now, we do the same thing, but for SQL. What's more surprising here,
though, is that the result is the same. We were able to query our resolver
through SQL, just the same as we queried it through GraphQL.

```ruby
require_relative 'wire_up_sql'
$sql.execute('select id, title from posts where id = 123').to_h
# => {"data"=>{"posts"=>{"id"=>123, "title"=>"a"}}}
```


How?
----

I parsed the SQL "create table" statements, tracked the tables, and then when
the query came in, parsed that, looked up the table, got the args off the "select"
statement, and handed that to the resolver of the selected table.


Conclusion
----------

So, hopefully at this point I can say: "Why didn't GraphQL choose an existing
language like SQL or Cypher or Datalog or Relational Algebra or whatever?"
