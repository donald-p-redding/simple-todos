class SessionPersistance
  def initialize(session)
    @session = session
    @session[:lists] ||= []
  end

  def create_new_list(list_name)
    id = next_element_id(@session[:lists])
    @session[:lists] << ({id: id, name: list_name, todos: []})
  end

  def delete_todo_list(list_id)
    @session[:lists].reject! { |list| list[:id] == list_id}
  end

  def add_todo_to_list(list_id, todo_name)
    list = find_list(list_id)
    id = next_element_id(list[:todos])

    list[:todos] << {id: id, name: todo_name, completed: false}
  end

  def delete_todo_from_list(list_id, todo_id)
    list = find_list(list_id)

    list[:todos].reject! { |todo| todo[:id] == todo_id}
  end

  def update_todo_status(list_id, todo_id, status)
    list = find_list(list_id)

    todo = list[:todos].find { |todo| todo[:id] == todo_id }

    todo[:completed] = status
  end

  def mark_all_todos_complete(list_id)
    list = find_list(list_id)
    list[:todos].each {|todo| todo[:completed] = true}
  end

  def all_lists
    @session[:lists]
  end

  def find_list(id)
    @session[:lists].find { |list| list[:id] == id}
  end

  def update_list_name(list_id, new_name)
    list = find_list(list_id)
    list[:name] = new_name
  end

  def next_element_id(elements)
    max_id = elements.map { |todo| todo[:id] }.max || 0
    next_id = max_id + 1
  end

  def size
    @session[:lists].size
  end
end