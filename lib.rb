require 'pg_query'

class Sql
  Type    = Struct.new :name, :fields
  Field   = Struct.new :name
  Resolve = Struct.new :type, :resolver
  Select  = Struct.new :type, :fields, :where do
    def initialize(type:, fields:, where:)
      super type, fields, where
    end
  end

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
    statements = PgQuery.parse(raw_sql).tree
    raise "idk #{ast.inspect}" if statements.size != 1
    from_ast statements[0]
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
        Type.new(
          from_ast(create['relation']),
          create['tableElts'].map { |h| Field.new from_ast h },
        )
      elsif ast.key? 'SelectStmt'
        stmt = ast['SelectStmt']
        expr = stmt['whereClause']['A_Expr']
        Select.new(
          type:   from_ast(stmt['fromClause'][0]), # => "posts"
          fields: from_ast(stmt['targetList']),    # => ["id", "title"]
          where:  [
            from_ast(expr['name'][0]),      # => "="
            from_ast(expr['lexpr']).intern, # => :id
            from_ast(expr['rexpr']),        # => 123
          ]
        )
      elsif ast.key? 'RangeVar'
        from_ast ast['RangeVar']['relname']
      elsif ast.key? 'fields'
        from_ast ast['fields'][0]
      elsif ast.key? 'colname'
        from_ast ast['colname']
      elsif ast.key? 'stmt'
        from_ast ast['stmt']
      elsif ast.key? 'val'
        from_ast ast['val']
      elsif ast.size == 1
        from_ast ast.values.first
      else
        raise "AST: #{ast.inspect}"
      end
    else
      raise "AST: #{ast.inspect}"
    end
  end
end
