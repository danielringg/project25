require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

get('/profile/:user') do
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    # if logged_in = true
    #     slim(:profile)
    # else
    #     slim(:login)
end

get('/register') do
    slim(:login)
end

post('/register') do
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    username = params["username"]
    password = params["password"] 
    password_confirmation = params["confirm_password"]
    result = db.execute("SELECT id FROM users WHERE username=?", @username)
    if result.empty?
        if password == password_confirmation
            password_digest = BCrypt::Password.create(password)
            db.execute("INSERT INTO users(username, password) VALUES (?, ?)" [username, password_digest])
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
    # set_error
end

get('/library') do
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM films")
    slim(:library)
end