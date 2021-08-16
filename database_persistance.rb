require "pg"

class DatabasePersistance
  def initialize(logger)
    @connection = if Sinatra::Base.production?
                    PG.connect(ENV['DATABASE_URL'])
                  else
                    PG::connect(dbname: "todos")
                  end
    @logger = logger
  end

  def disconnect
    @connection.close
  end

  def query(statement, *params)
    puts @logger.info "#{statement}: #{params}"
    @connection.exec_params(statement, params)
  end

  def all_lists
    sql = "SELECT * FROM lists ORDER BY id ASC"
    result = query(sql)

    result.map do |tuple|
      {id: tuple["id"].to_i , name: tuple["name"] , todos: fetch_todos(tuple["id"])}
    end
  end

  def create_new_list(list_name)
    sql = "INSERT INTO lists (name) VALUES
            ($1)"
    query(sql, list_name)
  end

  def delete_todo_list(list_id)
    sql = <<~SQL
            DELETE FROM lists
            WHERE id = $1
          SQL
    query(sql, list_id)
  end

  def add_todo_to_list(list_id, todo_name)
    sql = <<~SQL
            INSERT INTO todos (list_id, name) VALUES
            ($1, $2)
          SQL
    query(sql, list_id, todo_name)
  end

  def delete_todo_from_list(list_id, todo_id)
    sql = <<~SQL
            DELETE FROM todos
            WHERE list_id = $1 AND id = $2
          SQL
    query(sql, list_id, todo_id)
  end

  def update_todo_status(list_id, todo_id, status)
    sql = <<~SQL
            UPDATE todos
            SET completed = $3
            WHERE list_id = $1 AND id = $2
          SQL
    query(sql, list_id, todo_id, status.to_s)
  end

  def mark_all_todos_complete(list_id)
    sql = <<~SQL
            UPDATE todos
            SET completed = 't'
            WHERE list_id = $1
          SQL
    query(sql, list_id)
  end

  def find_list(list_id)
    sql = <<~SQL
            SELECT * FROM lists WHERE id = $1
          SQL

    result = query(sql, list_id)
    result.map { |tuple| { id: tuple["id"].to_i, name: tuple["name"], todos: fetch_todos(list_id) } }.first
  end

  def update_list_name(list_id, new_name)
    sql = <<~SQL
            UPDATE lists
            SET name = $2
            WHERE id = $1
          SQL
    query(sql, list_id, new_name)
  end

  private
  def fetch_todos(list_id)
    sql = <<~SQL
            SELECT * FROM todos WHERE todos.list_id = $1
            ORDER BY id ASC
          SQL
    result = query(sql, list_id)
    todos = result.map { |tuple| {id: tuple["id"].to_i, name: tuple["name"], completed: tuple["completed"] == "t"} }
  end

end
