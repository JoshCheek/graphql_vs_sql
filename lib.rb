require 'pg_query'

class Sql
  Resolve = Struct.new :type, :resolver
  Type    = Struct.new :name, :fields
  Field   = Struct.new :name # should include more data (eg field type), but that data is getting parsed as integers (probably values of a C enum)
  Select  = Struct.new :type, :fields, :where

  def define(type:, resolve:)
    t = parse type
    resolvers[t.name] = Resolve.new t, resolve
  end

  def execute(raw_query)
    query            = parse(raw_query)
    op, field, value = query.where # super fkn iffy, buuuut just a POC
    result           = resolvers[query.type].resolver[nil, {field => value}, {}]
    data             = query.fields.map { |field| [field, result[field]] }.to_h
    { 'data' => { query.type => data } }
  end

  private

  def resolvers
    @resolvers ||= {}
  end

  def parse(raw_sql)
    from_ast PgQuery.parse(raw_sql).tree[0]
  end

  def from_ast(ast)
    case ast
    when String, Integer
      ast
    when Array
      ast.map { |child| from_ast child }
    when Hash
      if ast.key? 'CreateStmt'
        create = ast['CreateStmt']
        Type.new from_ast(create['relation']),
                 create['tableElts'].map { |h| Field.new from_ast h }
      elsif ast.key? 'SelectStmt'
        stmt = ast['SelectStmt']
        expr = stmt['whereClause']['A_Expr']
        Select.new from_ast(stmt['fromClause'][0]),  # => "posts"
                   from_ast(stmt['targetList']),     # => ["id", "title"]
                   [ from_ast(expr['name'][0]),      # => "="
                     from_ast(expr['lexpr']).intern, # => :id
                     from_ast(expr['rexpr']),        # => 123
                   ]
      elsif ast.key? 'RangeVar' then from_ast ast['RangeVar']['relname']
      elsif ast.key? 'fields'   then from_ast ast['fields'][0]
      elsif ast.key? 'colname'  then from_ast ast['colname']
      elsif ast.key? 'stmt'     then from_ast ast['stmt']
      elsif ast.key? 'val'      then from_ast ast['val']
      elsif ast.size == 1       then from_ast ast.values.first
      else raise "AST: #{ast.inspect}"
      end
    else raise "AST: #{ast.inspect}"
    end
  end
end
