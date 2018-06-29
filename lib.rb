require 'pg_query'

class Sql
  Type    = Struct.new :name, :resolver, :fields
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
    op, field, value = query.where
    result           = resolvers[query.type].resolver[nil, {field => value}, {}]
    data             = query.fields.map { |field| [field, result[field]] }.to_h
    { "data" => { query.type => data } }
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
      if ast.key? 'RangeVar'
        from_ast ast['RangeVar']['relname']
      elsif ast.key? "CreateStmt"
        create       = ast["CreateStmt"]
        type         = Type.new nil, nil, []
        type.name    = from_ast create["relation"] # => "posts"
        type.fields  = create["tableElts"].map { |h| Field.new from_ast h }
        type
      elsif ast.key? "SelectStmt"
        stmt = ast["SelectStmt"]
        expr = stmt["whereClause"]['A_Expr']
        Select.new(
          type:   from_ast(stmt["fromClause"][0]), # => "posts"
          fields: from_ast(stmt["targetList"]),    # => ["id", "title"]
          where:  [
            from_ast(expr['name'][0]),      # => "="
            from_ast(expr['lexpr']).intern, # => :id
            from_ast(expr['rexpr']),        # => 123
          ]
        )
      elsif ast.key? 'ResTarget'
        from_ast ast['ResTarget']
      elsif ast.key? 'val'
        from_ast ast['val']
      elsif ast.key? 'Integer'
        from_ast ast['Integer']
      elsif ast.key? 'ColumnRef'
        from_ast ast['ColumnRef']
      elsif ast.key? 'fields'
        from_ast ast['fields'][0]
      elsif ast.key? 'String'
        from_ast ast['String']
      elsif ast.key? 'str'
        from_ast ast['str']
      elsif ast.key? 'A_Const'
        from_ast ast['A_Const']
      elsif ast.key? 'ival'
        from_ast ast['ival']
      elsif ast.key? 'ColumnDef'
        from_ast ast['ColumnDef']
      elsif ast.key? 'colname'
        from_ast ast['colname']
      elsif ast.key? 'RawStmt'
        from_ast ast['RawStmt']
      elsif ast.key? 'stmt'
        from_ast ast['stmt']
      else
        raise "AST: #{ast.inspect}"
      end
    else
      raise "AST: #{ast.inspect}"
    end
  end
end
