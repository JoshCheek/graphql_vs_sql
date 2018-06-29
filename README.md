GraphQL vs SQL
==============

I asked on [Twitter](https://twitter.com/josh_cheek/status/1012490394683224064)
why GraphQL didn't just roll with an existing query language like SQL or Cypher.
I think people misunderstood the question as suggesting we should
give clients query access to the database.

Instead, I was saying that if they want to map a query language to app code,
then why not choose an existing
query language that everyone already knows? Just because it's SQL doesn't mean it's
implemented by a relational database, it's "Structured Query Language", not
"Relational Database Query Language"

To illustrate this, I created a SQL equivalent to GraphQL.

Proof of Concept
----------------

The entry point is [`main.rb`](main.rb), which begins by defining a `Post` structure that
represents the data we might query from our database. Then it defines a `RESOLVER`,
the lambda that we will provide to connect a query for a post to our Post structure.

```ruby
RESOLVER = -> (obj, args, ctx) { Post.new args[:id], 'a', 'b', ["a"] }
Post = Struct.new :id, :title, :body, :comments
```

Next, load the code that tells GraphQL about our types, and resolver.
Then query the GraphQL schema it created.
We see that GraphQL maped the query to the resolver,
provided the id of `123`, and returned the resolver's post.

```ruby
require_relative 'wire_up_graphql'
$graphql.execute('query { post(id: 123) { id title } }').to_h
# => {"data"=>{"post"=>{"id"=>123, "title"=>"a"}}}
```

Now we do the same thing, but for SQL.
Surprisingly, the result is the same!

```ruby
require_relative 'wire_up_sql'
$sql.execute('select id, title from posts where id = 123').to_h
# => {"data"=>{"posts"=>{"id"=>123, "title"=>"a"}}}
```

We were able to query our resolver through SQL, just the same as we queried it through GraphQL.


How?
----

I parsed the SQL `create table` statements ([here](wire_up_sql.rb)),
tracked the tables, and then when the query came in, parsed that,
looked up the table, got the args off the `select` statement,
and handed that to the resolver of the selected table.


Conclusion
----------

Finally someone chimed in with the answer:

> It’s a very narrow subset of SQL. No aggregates, no functions, no arbitrary joins.
> FB had FQL before GraphQL. It looked like SQL, so people expected all the features
> of SQL. GraphQL was explicitly made to be more minimal
>
> -- [Matt Larraz](https://twitter.com/mattlarraz/status/1012686131530485760):
