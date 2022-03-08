require "sinatra"
require 'sinatra/content_for'
require "tilt/erubis"
require "pg"

require_relative "database_persistance"

configure(:development) do
  require "sinatra/reloader"
  also_reload "database_persistance.rb"
end

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

helpers do
  #Provides a class label for a list
  def list_class(list)
    status = all_complete?(list)
    'complete' if status
  end

  def all_complete?(list)
    list[:incomplete] == 0 && list[:total] > 0
  end

  #Sorts lists. Uncomplete come first.
  def sort_lists(lists,&block)
    complete_lists, incomplete_lists = @storage.all_lists.partition { |list| all_complete?(list) }
    
    incomplete_lists.each(&block)
    complete_lists.each(&block)
  end

  #Sorts todos. Uncomplete come first.
  def sort_todos(todos)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each { |todo| yield todo, todos.index(todo) }
    complete_todos.each { |todo| yield todo, todos.index(todo) }
  end
end

#Ensues no Todo list can have the same name as an existing list.
def list_name_taken?(new_name)
  @storage.all_lists.any? {|list| list[:name].downcase == new_name.downcase}
end

def item_name_taken?(todos, new_name)
  return "Name taken" if todos.any? {|todo| todo[:name].downcase == new_name.downcase}
end


# Validates user input. Returns error message if failure. Nil if no errors.
def error_with_list_name(name)
  if !(1..100).cover? name.strip.size
    "Please use 1 to 100 characters for entry"
  elsif list_name_taken?(name)
    "Name taken"
  end
end

#Validates a todo name. Returns error message if failure. Nil if no errors.
def error_with_todo_name(name)
  if !(1..100).cover? name.size
    "Please use 1 to 100 characters for entry"
  end
end


before do
  @storage = DatabasePersistance.new(logger)
end

after do
  @storage.disconnect
end


#Show all current lists
get "/lists" do
  @lists = @storage.all_lists
  erb :lists, layout: :layout
end


#Redirects to main page
get "/" do
  redirect "/lists"
end

# Creates a new list.
post "/lists" do
  list_name = params[:list_name].strip

  if error_msg = error_with_list_name(list_name)
    session[:error] = error_msg
    erb :new_list, layout: :layout
  else
    @storage.create_new_list(list_name)

    session[:succeuss] = "The list has succeussfully been added."
    redirect "/lists"
  end
end

# Edit an existing list.
post "/lists/:list_id" do
  @list_id = params[:list_id].to_i
  list_name = params[:list_name].strip

  @list = @storage.find_list(@list_id)

  if error_msg = error_with_list_name(list_name)
    session[:error] = error_msg
    erb :edit, layout: :layout
  else
    @storage.update_list_name(@list_id, list_name)

    session[:succeuss] = "The list has succeussfully been changed."
    redirect "/lists/#{@list_id}"
  end
end

#Creates a new Todo List
get "/lists/new" do
  erb :new_list, layout: :layout
end

#Views a single Todo List
get "/lists/:list_id" do
  @list_id = params[:list_id].to_i
  @list = @storage.find_list(@list_id)
  @todos = @storage.fetch_todos(@list_id)

  erb :single_list, layout: :layout
end

#Calls up the edit page for a Todo List.
get "/lists/:list_id/edit" do
  @list_id = params[:list_id].to_i
  @list = @storage.find_list(@list_id)

  erb :edit, layout: :layout
end

# Delete an existing list.
post "/lists/:list_id/delete" do
  @list_id = params[:list_id].to_i

  @storage.delete_todo_list(@list_id)

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:succeuss] = "This list has been succeussfuly deleted."
    redirect "/lists"
  end
end

#Adds a todo to a list.
post "/lists/:list_index/todos" do
  @list_id = params[:list_index].to_i
  @list = @storage.find_list(@list_id)
  @todos = @storage.fetch_todos(@list_id)


  todo_name = params[:todo].strip

  error_msg = error_with_todo_name(todo_name) || item_name_taken?(@todos, todo_name)
  if error_msg
    session[:error] = error_msg
    erb :single_list, layout: :layout
  else
    @storage.add_todo_to_list(@list_id, todo_name)
    session[:succeuss] = "The todo has been added."

    redirect "/lists/#{@list_id}"
  end
end

#Deletes a todo from a list.
post "/lists/:list_index/todos/:todo_id/delete" do
  @list_id = params[:list_index].to_i
  todo_id = params[:todo_id].to_i

  @storage.delete_todo_from_list(@list_id, todo_id)

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:succeuss] = "The todo has been removed."
    redirect "/lists/#{@list_id}"
  end
end

#Updates the satus of a todo.
post "/lists/:list_id/todos/:todo_id" do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  status = params[:completed] == 'true'

  @storage.update_todo_status(list_id, todo_id, status)

  redirect "/lists/#{list_id}"
end

# #Marks all todos as complete.
post "/lists/:list_id/complete_all" do
  list_id = params[:list_id].to_i

  @storage.mark_all_todos_complete(list_id)
  session[:succeuss] = "All todos have been completed."

  redirect "/lists/#{list_id}"
end
