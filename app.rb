require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions

get('/profile/:user') do
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true

    slim(:profile)
end

get ('/login') do
    slim(:login)
end

post ('/login') do
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    username = params["username"]
    password = params["password"]
    result = db.execute("SELECT * FROM users WHERE username = ?", username)
    password_digest = result.first['password']
    id = result.first['id']
    if BCrypt::Password.new(password_digest) == password
        session[:id] = id
        # flash[:alert] = "Successfully logged in as "
        redirect('/profile')
    else
        set_error("Wrong password")
        redirect('/error')
    end
end

get('/register') do
    slim(:register)
end

post('/register') do
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    username = params["username"]
    password = params["password"] 
    password_confirmation = params["confirm_password"]
    result = db.execute("SELECT id FROM users WHERE username=?", username)
    if result.empty?
        if password == password_confirmation
            password_digest = BCrypt::Password.create(password)
            db.execute("INSERT INTO users(username, password) VALUES (?, ?)", [username, password_digest])
            redirect('/library')
        else
            set_error("Passwords do not match")
            redirect('/error')
        end
    else
        set_error("Username already exists")
        redirect('/error')
    end
end

get('/error') do
    #????????????
end

get('/library') do
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM films")
    slim(:library)
end