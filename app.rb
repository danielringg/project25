require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions

get('/profile') do
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
        session[:username] = username
        session[:user_id] = user['id']
        redirect('/profile')
    else
        "Wrong password"
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
            "Passwords do not match"
        end
    else
        "Username already exists"
    end
end

get('/library') do
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM films")
    slim(:library)
end

get('/store') do
    slim(:store)
end

post('/store/open') do
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true

    user_id = session[:user_id]

    cards = db.execute("SELECT * FROM films ORDER BY RANDOM() LIMIT 3")
    cards.each do |card|
        db.execute("INSERT INTO user_card_join (user_id, film_id) VALUES (?, ?)", [user_id, cards['id']])
    end
    @cards = cards
    slim(:pack_opened) #? på nåt sätt ska jag displaya korten som man får
end

get('/crud') do
    slim(:crud)
end

post('/crud/new') do
    name = params[:name]
    id = params[:id]
    year = params[:year]
    rarity = params[:rarity]
    poster = params[:poster]
    db = SQLite3::Database.new("db/database.db")
    @result = db.execute("INSERT INTO films (name, id, year, rarity, poster) VALUES (?, ?, ?, ?, ?)", [name, id, year, rarity, poster])
    redirect("/library")
end

post('/crud/edit') do
    name = params[:name]
    id = params[:id]
    year = params[:year]
    rarity = params[:rarity]
    poster = params[:poster]
    db = SQLite3::Database.new("db/database.db")
    @result = db.execute("UPDATE films SET name=?, year=?, rarity=?, poster=? WHERE id=?", [name, year, rarity, poster, id])
    redirect("/library")
end

post('/crud/delete') do
    id = params[:id]
    db = SQLite3::Database.new("db/database.db")
    @result = db.execute("DELETE FROM films WHERE id=?", [id])
    redirect("/library")
end